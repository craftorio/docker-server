FROM azul/zulu-openjdk-alpine:8-jre AS base

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
    fc-cache -fv
 
RUN groupadd -g 1000 craftorio \
    && useradd -u 1000 -d /opt/craftorio -g craftorio -s /bin/bash -m craftorio \
    && mkdir -p /opt/craftorio \
    && chown craftorio:craftorio /opt/craftorio

FROM base AS builder
USER craftorio

ARG MC_VERSION=1.12.2
ARG FORGE_VERSION=14.23.5.2860

WORKDIR /opt/craftorio

# Copy java launcher
COPY --chown=craftorio:craftorio --chmod=0700 java-jar-launcher.sh java-jar-launcher.sh

# Copy ultra-core
COPY --chown=craftorio:craftorio ultra-core/ultra-core-agent-java8.jar ultra-core-agent.jar

# Copy and map ultra-core config
COPY --chown=craftorio:craftorio ultra-core/ultra-core-agent-server.conf.tpl ultra-core-agent-server.conf.tpl

# Copy forge installer
COPY --chown=craftorio:craftorio server/forge/${MC_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar forge-installer.jar

# Install forge (no caching - installer needs clean directory)
RUN java -jar forge-installer.jar --installServer --debug \
    && rm forge-installer.jar

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
    /opt/craftorio/tacz

FROM base
USER craftorio
WORKDIR /opt/craftorio

# Configuration parameters (not secrets) for authentication servers
ENV MC_AUTH_SERVER=auth.craftorio.com
ENV MC_AUTH_SESSION_SERVER=sessionserver.craftorio.com

COPY --from=builder --chown=craftorio:craftorio /opt/craftorio/ /opt/craftorio/
COPY --chown=craftorio:craftorio --chmod=0700 entrypoint.sh /entrypoint.sh

VOLUME ["/opt/craftorio/dynmap", "/opt/craftorio/worlds", "/opt/craftorio/plugins", "/opt/craftorio/mods", "/opt/craftorio/config", "/opt/craftorio/logs", "/opt/craftorio/config-server", "/opt/craftorio/scripts", "/opt/craftorio/Flan", "/opt/craftorio/tacz"]

EXPOSE 25565

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "server_start" ]