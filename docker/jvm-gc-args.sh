# Sets JVM_GC_ARGS based on JVM_GC (g1 or shenandoah).
JVM_GC=${JVM_GC:-g1}

if [ "$JVM_GC" = "shenandoah" ]; then
    if ! java -XX:+UseShenandoahGC -version >/dev/null 2>&1; then
        echo "WARNING: Shenandoah GC is not available in this JRE, falling back to G1" >&2
        JVM_GC=g1
    fi
fi

case "$JVM_GC" in
    shenandoah)
        JVM_GC_ARGS="-XX:+UseShenandoahGC \
            -XX:ShenandoahGCHeuristics=adaptive \
            -XX:+DisableExplicitGC \
            -XX:+PerfDisableSharedMem"
        ;;
    g1)
        JVM_GC_ARGS="-XX:+UseG1GC \
            -XX:+ParallelRefProcEnabled \
            -XX:MaxGCPauseMillis=500 \
            -XX:+DisableExplicitGC \
            -XX:G1HeapRegionSize=16M \
            -XX:G1ReservePercent=15 \
            -XX:InitiatingHeapOccupancyPercent=35 \
            -XX:+PerfDisableSharedMem"
        ;;
    *)
        echo "WARNING: Unknown JVM_GC=$JVM_GC, using G1" >&2
        JVM_GC=g1
        JVM_GC_ARGS="-XX:+UseG1GC \
            -XX:+ParallelRefProcEnabled \
            -XX:MaxGCPauseMillis=500 \
            -XX:+DisableExplicitGC \
            -XX:G1HeapRegionSize=16M \
            -XX:G1ReservePercent=15 \
            -XX:InitiatingHeapOccupancyPercent=35 \
            -XX:+PerfDisableSharedMem"
        ;;
esac
