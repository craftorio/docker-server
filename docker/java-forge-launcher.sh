#!/bin/sh

# Setup virtual display if Xvfb is available (for GUI components compatibility)
CLEANUP_DISPLAY=false
if command -v Xvfb > /dev/null 2>&1 && [ -z "$DISPLAY" ]; then
    echo "Starting virtual display for GUI compatibility..."
    Xvfb :99 -screen 0 1024x768x16 -nolisten tcp -fbdir /var/tmp > /dev/null 2>&1 &
    XVFB_PID=$!
    export DISPLAY=:99
    CLEANUP_DISPLAY=true
    sleep 1
fi

cleanup() {
    if [ "$CLEANUP_DISPLAY" = "true" ] && [ -n "$XVFB_PID" ]; then
        echo "Cleaning up virtual display..."
        kill $XVFB_PID 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

FORGE_ARGS=$(find libraries/net/minecraftforge/forge -name unix_args.txt 2>/dev/null | head -1)
if [ -z "$FORGE_ARGS" ]; then
    echo "ERROR: Forge unix_args.txt not found under libraries/net/minecraftforge/forge"
    exit 1
fi

exec java $INVOCATION_EXTRA_ARGS \
    -Xms${JVM_MEMORY_START:-2048M} \
    -Xmx${JVM_MEMORY_MAX:-4096M} \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=500 \
    -XX:+DisableExplicitGC \
    -XX:G1HeapRegionSize=16M \
    -XX:G1ReservePercent=15 \
    -XX:InitiatingHeapOccupancyPercent=35 \
    -XX:+PerfDisableSharedMem \
    -Djava.awt.headless=true \
    -Dfile.encoding=UTF8 \
    -Dsun.jnu.encoding=UTF8 \
    @user_jvm_args.txt \
    @"$FORGE_ARGS" \
    "$@"
