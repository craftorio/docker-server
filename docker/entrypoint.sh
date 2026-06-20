#!/bin/bash
set -e
if [[ -n $DEBUG ]]; then set -x; fi

INIT_TIMEOUT=${INIT_TIMEOUT:-"600s"}
INIT_TIMEOUT_SECONDS=${INIT_TIMEOUT_SECONDS:-600}
MC_RESTART_DELAY=${MC_RESTART_DELAY:-10}

# User that should run the server
USERNAME=${MC_USER:-"craftorio"}

# Path to craftorio server directory
MCPATH=${MCPATH:-"/opt/craftorio"}

LAUNCHER="./java-jar-launcher.sh"

# Modern Forge (1.17+) uses run.sh + unix_args.txt instead of a single jar
if [[ -f "${MCPATH}/run.sh" ]]; then
    FORGE_UNIX_ARGS=$(find "${MCPATH}/libraries/net/minecraftforge/forge" -name unix_args.txt 2>/dev/null | head -1)
    if [[ -n "$FORGE_UNIX_ARGS" ]]; then
        SERVICE="run.sh"
        LAUNCHER="./java-forge-launcher.sh"
        INVOCATION="nogui"
        echo "Found modern Forge server: ${SERVICE}"
    fi
fi

# Look for server jar files in order of preference
if [ -z "$SERVICE" ]; then
    SERVICE=`basename $(find ${MCPATH} -maxdepth 1 -iname "arclight-server.jar" | head -1)`
    if [ -n "$SERVICE" ]; then
        echo "Found Arclight server jar: $SERVICE"
    fi
fi

# Fallback to other server jars
if [ -z "$SERVICE" ]; then
    SERVICE=`basename $(find ${MCPATH} -maxdepth 1 -iname "forge-*-universal.jar" -or -iname "forge-*.jar" -or -iname "minecraft_server.*.jar" -or -iname "*server*.jar" | head -1)`
    echo "Found server jar: $SERVICE"
fi

# Look for other modded server jars
if [ -z "$SERVICE" ]; then
    SERVICE=`basename $(find ${MCPATH} -maxdepth 1 -iname "kcauldron*.jar" -or -iname "mohist*.jar" -or -iname "thermos*.jar" -or -iname "arclight*.jar" | head -1)`
    echo "Found modded server jar: $SERVICE"
fi

# Ultimate fallback - any jar file (excluding known installers)
if [ -z "$SERVICE" ]; then
    SERVICE=`basename $(find ${MCPATH} -maxdepth 1 -name "*.jar" ! -name "*installer*" | head -1)`
    echo "Fallback jar: $SERVICE"
fi

if [ -z "$SERVICE" ]; then
    echo "ERROR: No server installation found!"
    exit 1
fi

echo "Selected server: $SERVICE"

# Name to use for the screen instance
SCREEN="craftorio_server_screen"

# Initial memory usage
export JVM_MEMORY_START=${JVM_MEMORY_START:-${MC_INIT_MEMORY:-"2048M"}}

# Maximum amount of memory to use
export JVM_MEMORY_MAX=${JVM_MEMORY_MAX:-${MC_MAX_MEMORY:-"4096M"}}

export INVOCATION_EXTRA_ARGS="-Dultra.core.config=${MCPATH}/ultra-core-agent-server.conf -javaagent:${MCPATH}/ultra-core-agent.jar -Djava.awt.headless=true -Dfile.encoding=UTF8 -Dsun.jnu.encoding=UTF8"

JARFILE=$MCPATH/$SERVICE
if [[ -z "${INVOCATION:-}" ]]; then
    INVOCATION="$JARFILE"
fi

PIDFILE=${MCPATH}/${SCREEN}.pid

cd $MCPATH && echo "eula=true" > eula.txt

config_server_is_empty() {
    [[ 0 -eq $(ls "${MCPATH}/config-server" 2>/dev/null | grep -v eula.txt | wc -l) ]]
}

wait_for_pattern_in_file() {
    local pattern="$1"
    local file="$2"
    local timeout="$3"
    local label="$4"
    local elapsed=0

    while ! grep -E "${pattern}" "${file}" >/dev/null 2>&1; do
        if (( elapsed >= timeout )); then
            echo "${label} timeout after ${timeout}s"
            return 1
        fi
        if (( elapsed > 0 && elapsed % 15 == 0 )); then
            echo "${label}... still starting (${elapsed}s elapsed)"
            if [[ -f "${file}" ]]; then
                tail -n 3 "${file}" 2>/dev/null || true
            fi
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    return 0
}

migrate_generated_configs() {
    shopt -s nullglob

    files=("${MCPATH}"/*.yml)
    if (( ${#files[@]} )); then
        mv "${files[@]}" "${MCPATH}/config-server/"
    fi

    for file in "${MCPATH}"/*.conf; do
        [[ "$(basename "${file}")" == "ultra-core-agent-server.conf.tpl" ]] && continue
        mv "${file}" "${MCPATH}/config-server/"
    done

    for file in server.properties banned-players.json banned-ips.json ops.json whitelist.json; do
        if [[ -f "${MCPATH}/${file}" ]]; then
            mv "${MCPATH}/${file}" "${MCPATH}/config-server/${file}"
        fi
    done
}

seed_config_server() {
    if [[ -d "${MCPATH}/config-server.defaults" ]] && \
       [[ 0 -lt $(find "${MCPATH}/config-server.defaults" -mindepth 1 ! -name eula.txt | wc -l) ]]; then
        cp -a "${MCPATH}/config-server.defaults/." "${MCPATH}/config-server/"
        echo "Initialized config-server from image defaults."
        return 0
    fi

    migrate_generated_configs
    if config_server_is_empty; then
        return 1
    fi

    echo "Initialized config-server from bundled server files."
    return 0
}

is_running() {
    if [ -f "$PIDFILE" ]; then 
        pid=$(head -1 $PIDFILE)
        
        if ! ps ax | grep -v grep | grep "${pid}" | grep "${SCREEN}" > /dev/null; then
          if ps aux | grep "${SCREEN}" | grep -v grep; then
            pid=$(ps aux | grep "${SCREEN}" | grep -v grep | awk '{print $2}')
            echo $pid > $PIDFILE
            echo "Pid restored to $pid"
          fi
        fi
        
        if ps ax | grep -v grep | grep "${pid}" | grep "${SCREEN}" > /dev/null; then
            return 0
        else
            return 1
        fi
    else
        if ps ax | grep -v grep | grep "${SCREEN} ${INVOCATION}" > /dev/null; then
            echo "No PIDFILE found, but server running."
            echo "Re-creating the PIDFILE."

            pid=$(ps ax | grep -v grep | grep "${SCREEN} ${INVOCATION}" | cut -f1 -d' ')
            
            echo $pid > $PIDFILE

            return 0
        else
            return 1
        fi
    fi
}

server_say() {
    if is_running; then
        echo "Said: $1"
        server_command "say $1"
    else
        echo "$SERVICE was not running. Not able to say anything."
    fi
}

server_stop() {
    server_say "The server is shutting down!"
    echo "Saving worlds..."
    server_command save-all
    sleep 10

    echo "Stopping server..."
    server_command stop
    sleep 0.5
    
    seconds=0
    while is_running; do
        sleep 1
        seconds=$(($seconds+1))
        if [ $seconds -eq 10 ]; then
            echo "Waiting for server shutdown..."
        fi
        if [ $seconds -eq 30 ]; then
            echo "Timeout reached, terminating..."
            kill -9 $(head -1 $PIDFILE)
        fi
    done

    if [ $seconds -lt 30 ]; then
        echo "Server shutdown successfully..."
    fi
}

server_start() {
    mkdir -p logs
    [[ -e logs/latest.log ]] && rm -f logs/latest.log
    envsubst < ${MCPATH}/ultra-core-agent-server.conf.tpl > ${MCPATH}/ultra-core-agent-server.conf
    
    echo "Starting server: $INVOCATION"
    echo "Arclight/Forge startup can take 1-3 minutes before new log lines appear."
    screen -dmS "$SCREEN" env \
        JVM_MEMORY_START="$JVM_MEMORY_START" \
        JVM_MEMORY_MAX="$JVM_MEMORY_MAX" \
        INVOCATION_EXTRA_ARGS="$INVOCATION_EXTRA_ARGS" \
        bash -c "cd ${MCPATH} && ${LAUNCHER} ${INVOCATION} 2>&1 | tee -a logs/console.log"
    screen -list | grep "\.$SCREEN" | cut -f1 -d'.' | tr -d -c 0-9 > $PIDFILE
}

follow_server_logs() {
    tail -F logs/latest.log logs/console.log 2>/dev/null &
    echo $!
}

server_supervise() {
    local tail_pid

    while true; do
        tail_pid=$(follow_server_logs)

        while is_running; do
            sleep 5
        done

        kill "$tail_pid" 2>/dev/null || true
        wait "$tail_pid" 2>/dev/null || true

        echo "Server process exited at $(date -u +%Y-%m-%dT%H:%M:%SZ), restarting in ${MC_RESTART_DELAY}s..."
        sleep "$MC_RESTART_DELAY"

        server_start
        wait_for_pattern_in_file '.' "${MCPATH}/logs/latest.log" 120 "Waiting for server log after restart" || {
            echo "Restart failed: log file not created within 120s, retrying..."
        }
    done
}

server_init() {
    echo "Detected first start without bundled defaults, running full initialization..."
    sleep 1

    FINISH_PATTERN='Done \(.*\)! For help, type "help"'
    ${LAUNCHER} ${INVOCATION} > /proc/self/fd/1 2>&1 &
    wait_for_pattern_in_file "${FINISH_PATTERN}" "${MCPATH}/logs/latest.log" "${INIT_TIMEOUT_SECONDS}" "Server initialization" || {
        echo "Init timeout reached (${INIT_TIMEOUT}). Terminating..."
        exit 1
    }

    sleep 2

    pid=$(ps aux | grep -v grep | grep "${LAUNCHER}" | awk '{ print $2 }')
    
    if [ -n "$pid" ]; then
        kill -15 $pid
        wait $pid 2>/dev/null || /bin/true
    fi
    
    find /opt/craftorio -name "*.log" -type f -delete 2>/dev/null || true
    migrate_generated_configs
}

server_command() {
    if is_running; then
        bash -c "screen -p 0 -S $SCREEN -X eval 'stuff \"$(eval echo $1)\"\015'"
    else
        echo "$SERVICE was not running. Not able to run command."
    fi
}

shutdown() {
    server_stop
    exit 0
}

trap shutdown SIGTERM SIGINT SIGTSTP

if [ -z $1 ] || [ $1 == 'server_start' ]; then
    if config_server_is_empty; then
        if ! seed_config_server; then
            server_init
        fi
    fi

    while read filename; do
        if [[ -e "/opt/craftorio/${filename}" ]]; then
            rm -f "/opt/craftorio/${filename}"
        fi
        ln -s -f "/opt/craftorio/config-server/${filename}" "/opt/craftorio/${filename}"
    done < <(ls /opt/craftorio/config-server/) 

    server_start
    wait_for_pattern_in_file '.' "${MCPATH}/logs/latest.log" 120 "Waiting for server log file" || {
        echo "Server log file was not created within 120s"
        exit 1
    }
    server_supervise
else
    exec "$@"
fi
