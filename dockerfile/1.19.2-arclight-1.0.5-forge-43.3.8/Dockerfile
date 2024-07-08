FROM azul/zulu-openjdk-alpine:17-jre-headless AS base

RUN echo "http://dl-2.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories; \
    apk --no-cache add \
    shadow \
    screen \
    bash \
    gettext;

RUN apk add --no-cache fontconfig && \
    ln -s /usr/lib/libfontconfig.so.1 /usr/lib/libfontconfig.so && \
    ln -s /lib/libuuid.so.1 /usr/lib/libuuid.so.1 && \
    ln -s /lib/libc.musl-x86_64.so.1 /usr/lib/libc.musl-x86_64.so.1

ENV LD_LIBRARY_PATH=/usr/lib
 
RUN groupadd craftorio \
    && useradd -d /opt/craftorio -g craftorio -s /bin/bash -m craftorio \
    && mkdir -p /opt/craftorio \
    && chown craftorio:craftorio /opt/craftorio

FROM base AS builder
USER craftorio

ARG MC_VERSION=1.19.2
ARG FORGE_VERSION=43.3.8
ARG ARCLIGHT_VERSION=1.0.5

WORKDIR /opt/craftorio

# Copy java launcher
COPY --chown=craftorio:craftorio --chmod=0700 java-jar-launcher.sh java-jar-launcher.sh

# Copy ultra-core
COPY ultra-core/ultra-core-agent-java8.jar ultra-core-agent.jar

# Copy and map ultra-core config
COPY ultra-core/ultra-core-agent-server.conf.tpl ultra-core-agent-server.conf.tpl

# Copy arclight 
COPY server/arclight/${MC_VERSION}/arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar

# Installing
RUN ./java-jar-launcher.sh arclight-forge-${MC_VERSION}-${ARCLIGHT_VERSION}.jar > /tmp/arclight-install.log 2> /tmp/arclight-install.err & \
    timeout 60s bash -c "until grep 'The server installed successfully' /tmp/arclight-install.log; do { tail -n1 /tmp/arclight-install.log; tail -n1 /tmp/arclight-install.err; sleep 1; } done;"

RUN mkdir -p \
    /opt/craftorio/worlds \
    /opt/craftorio/dynmap \
    /opt/craftorio/mods \
    /opt/craftorio/logs \
    /opt/craftorio/plugins \
    /opt/craftorio/config \
    /opt/craftorio/config-server \
    /opt/craftorio/scripts \
    /opt/craftorio/Flan

FROM base
USER craftorio
WORKDIR /opt/craftorio

ENV MC_AUTH_SERVER=auth.craftorio.com
ENV MC_AUTH_SESSION_SERVER=sessionserver.craftorio.com

COPY --from=builder /opt/craftorio/ /opt/craftorio/
COPY --chown=craftorio:craftorio --chmod=0700 entrypoint.sh /entrypoint.sh

VOLUME ["/opt/craftorio/dynmap", "/opt/craftorio/worlds", "/opt/craftorio/plugins", "/opt/craftorio/mods", "/opt/craftorio/config", "/opt/craftorio/logs", "/opt/craftorio/config-server", "/opt/craftorio/scripts", "/opt/craftorio/Flan"]

EXPOSE 25565

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "server_start" ]