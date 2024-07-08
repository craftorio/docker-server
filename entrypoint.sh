#!/bin/bash
set -e
if [[ -n $DEBUG ]]; then set -x; fi

INIT_TIMEOUT=${INIT_TIMEOUT:-"60s"}

# User that should run the server
USERNAME=${MC_USER:-"craftorio"}

# Path to craftorio server directory
MCPATH=${MCPATH:-"/opt/craftorio"}

# Name of the server jar
SERVICE=`basename $(find ${MCPATH} -maxdepth 1 -iname "arclight*.jar" -or  -iname "kcauldron*.jar" -or -iname "mohist*.jar" -or -iname "thermos*.jar" -or -iname "forge-*-universal.jar" -or -iname "forge-*.jar" -or -iname "minecraft_server.*.jar" | head -1)`

# Name to use for the screen instance
SCREEN="craftorio_server_screen"

# Initial memory usage
export JVM_MEMORY_START=${JVM_MEMORY_START:-${MC_INIT_MEMORY:-"1024M"}}

# Maximum amount of memory to use
# Remember: give the ramdisk enough space, subtract from the total amount
# of RAM available the size of your map and the RAM-consumption of your base system.
export JVM_MEMORY_MAX=${JVM_MEMORY_MAX:-${MC_MAX_MEMORY:-"1024M"}}

export INVOCATION_EXTRA_ARGS="-Dultra.core.config=${MCPATH}/ultra-core-agent-server.conf -javaagent:${MCPATH}/ultra-core-agent.jar";

JARFILE=$MCPATH/$SERVICE
INVOCATION="$JARFILE"

PIDFILE=${MCPATH}/${SCREEN}.pid

cd $MCPATH && echo "eula=true" > eula.txt

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
    while is_running
    do
        sleep 1
        seconds=$(($seconds+1))
        if [ $seconds -eq 10 ]; then
            echo "Waiting for server shutdown..."
        fi
    done
    
    if is_running; then
        echo "Timeout reached, terminating..."
        kill -9 $(head -1 $PIDFILE)
    else
        echo "Server shutdown successfully..."
    fi
}

server_start() {
    [[ -e logs/latest.log ]] && rm -f logs/latest.log
    envsubst < ${MCPATH}/ultra-core-agent-server.conf.tpl > ${MCPATH}/ultra-core-agent-server.conf
    echo "Invocating: $INVOCATION"
    screen -dmS $SCREEN bash -c "exec ./java-jar-launcher.sh $INVOCATION"
    screen -list | grep "\.$SCREEN" | cut -f1 -d'.' | tr -d -c 0-9 > $PIDFILE
}

server_init() {
    echo "Detected first start, beginning initialization..."
    sleep 1
    
    FINISH_PATTERN='Done \(.*\)! For help, type "help"'
    ./java-jar-launcher.sh $INVOCATION > /proc/self/fd/1 2>&1 &
    timeout "${INIT_TIMEOUT}" bash -c "until grep '${FINISH_PATTERN}' logs/latest.log > /dev/null 2> /dev/null; do sleep 1; done" || {
        echo "Init timout reached (${INIT_TIMEOUT}), terminating..."
        exit 1
    }
    
    pid=$(ps aux | grep -v grep | grep "$INVOCATION" | awk '{ print $1 }')
    
    if [ -n $pid ]; then
        kill -15 $pid
        wait $pid 2>/dev/null || /bin/true
    fi

    mv /opt/craftorio/*.yml /opt/craftorio/config-server/
    mv /opt/craftorio/*.conf /opt/craftorio/config-server/
    mv /opt/craftorio/server.properties /opt/craftorio/config-server/server.properties
    mv /opt/craftorio/banned-players.json /opt/craftorio/config-server/banned-players.json
    mv /opt/craftorio/banned-ips.json /opt/craftorio/config-server/banned-ips.json
    mv /opt/craftorio/ops.json /opt/craftorio/config-server/ops.json
    mv /opt/craftorio/whitelist.json /opt/craftorio/config-server/whitelist.json
}

server_command() {
    if is_running; then
        bash -c "screen -p 0 -S $SCREEN -X eval 'stuff \"$(eval echo $1)\"\015'"
    else
        echo "$SERVICE was not running. Not able to run command."
    fi
}

trap 'server_stop' SIGTSTP
trap 'server_stop' SIGINT

if [ -z $1 ] || [ $1 == 'server_start' ]; then
    if [[ 0 -eq $(ls /opt/craftorio/config-server | grep -v eula.txt | wc -l) ]]; then
        server_init
    fi

    while read filename; do
        if [[ -e "/opt/craftorio/${filename}" ]]; then
            rm -f "/opt/craftorio/${filename}"
        fi
        ln -s -f "/opt/craftorio/config-server/${filename}" "/opt/craftorio/${filename}"
    done < <(ls /opt/craftorio/config-server/) 

    server_start
    until [[ -e logs/latest.log ]]; do sleep 1; done
    tail -f logs/latest.log
else
    exec "$@"
fi
