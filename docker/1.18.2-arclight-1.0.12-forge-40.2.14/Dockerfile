FROM azul/zulu-openjdk-alpine:17-jre AS base

# Cache APK packages for faster builds
RUN --mount=type=cache,target=/var/cache/apk \
    echo "http://dl-2.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    apk add --no-cache \
    shadow \
    screen \
    bash \
    gettext \
    fontconfig \
    ttf-dejavu \
    ttf-liberation \
    fontconfig-dev \
    xvfb && \
    ln -sf /usr/lib/libfontconfig.so.1 /usr/lib/libfontconfig.so && \
    ln -sf /lib/libuuid.so.1 /usr/lib/libuuid.so.1 && \
    ARCH=$(uname -m); \
    if [ "$ARCH" = "x86_64" ]; then \
        ln -sf /lib/libc.musl-x86_64.so.1 /usr/lib/libc.musl-x86_64.so.1; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ln -sf /lib/libc.musl-aarch64.so.1 /usr/lib/libc.musl-aarch64.so.1; \
    fi && \
    fc-cache -fv

ENV LD_LIBRARY_PATH=/usr/lib

RUN groupadd -g 1000 craftorio \
    && useradd -u 1000 -d /opt/craftorio -g craftorio -s /bin/bash -m craftorio \
    && mkdir -p /opt/craftorio \
    && chown craftorio:craftorio /opt/craftorio

FROM base AS builder
USER craftorio

ARG MC_VERSION=1.18.2
ARG FORGE_VERSION=40.2.14
ARG ARCLIGHT_VERSION=1.0.12

WORKDIR /opt/craftorio

# Copy java launcher
COPY --chown=craftorio:craftorio --chmod=0700 java-jar-launcher.sh java-jar-launcher.sh

# Copy ultra-core
COPY --chown=craftorio:craftorio ultra-core/ultra-core-agent-java17.jar ultra-core-agent.jar

# Copy and map ultra-core config
COPY --chown=craftorio:craftorio ultra-core/ultra-core-agent-server.conf.tpl ultra-core-agent-server.conf.tpl

# Copy arclight server jar
COPY --chown=craftorio:craftorio server/arclight/${MC_VERSION}/arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar

# First run to cache libraries and patch - launcher handles GUI setup
# Use cache mount for libraries, then copy to permanent location
RUN --mount=type=cache,target=/tmp/cache-libraries,uid=1000,gid=1000 \
    --mount=type=cache,target=/tmp/cache-gradle,uid=1000,gid=1000 \
    mkdir -p /tmp/cache-libraries /tmp/cache-gradle && \
    chown craftorio:craftorio /tmp/cache-libraries /tmp/cache-gradle && \
    ln -sf /tmp/cache-libraries libraries && \
    ln -sf /tmp/cache-gradle .gradle && \
    echo "eula=true" > eula.txt && \
    export JVM_MEMORY_START=1024M && export JVM_MEMORY_MAX=2048M && \
    timeout 180s ./java-jar-launcher.sh arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar 2>&1 | tee /tmp/arclight-cache.log & \
    timeout 180s bash -c "until grep -E '(Done.*For help|Server started|Finished loading)' /tmp/arclight-cache.log 2>/dev/null; do sleep 2; done" && \
    echo "Arclight libraries cached successfully" && \
    pkill -f "arclight-forge" || true && \
    sleep 2 && \
    rm -f libraries .gradle && \
    cp -r /tmp/cache-libraries ./libraries 2>/dev/null || true && \
    cp -r /tmp/cache-gradle ./.gradle 2>/dev/null || true && \
    echo "Libraries copied to permanent location" && \
    find /opt/craftorio -name "*.log" -type f -delete 2>/dev/null || true && \
    echo "Cleaned up all log files"

# Rename to standard name for runtime
RUN mv arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar arclight-server.jar && \
    echo "Server files:" && ls -la /opt/craftorio/

RUN mkdir -p \
    /opt/craftorio/worlds \
    /opt/craftorio/dynmap \
    /opt/craftorio/mods \
    /opt/craftorio/logs \
    /opt/craftorio/plugins \
    /opt/craftorio/config \
    /opt/craftorio/config-server \
    /opt/craftorio/scripts \
    /opt/craftorio/Flan \
    /opt/craftorio/tacz \
    /opt/craftorio/resourcepacks \
    /opt/craftorio/datapacks

FROM base
USER craftorio
WORKDIR /opt/craftorio

# Configuration parameters (not secrets) for authentication servers
ENV MC_AUTH_SERVER=auth.craftorio.com
ENV MC_AUTH_SESSION_SERVER=sessionserver.craftorio.com

COPY --from=builder --chown=craftorio:craftorio /opt/craftorio/ /opt/craftorio/
COPY --chown=craftorio:craftorio --chmod=0700 entrypoint.sh /entrypoint.sh

VOLUME ["/opt/craftorio/dynmap", "/opt/craftorio/worlds", "/opt/craftorio/plugins", "/opt/craftorio/mods", "/opt/craftorio/config", "/opt/craftorio/logs", "/opt/craftorio/config-server", "/opt/craftorio/scripts", "/opt/craftorio/Flan", "/opt/craftorio/tacz", "/opt/craftorio/resourcepacks", "/opt/craftorio/datapacks"]

EXPOSE 25565

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "server_start" ]