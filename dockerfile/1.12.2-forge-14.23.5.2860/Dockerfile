FROM azul/zulu-openjdk-alpine:8-jre-headless AS base

RUN echo "http://dl-2.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories; \
    apk --no-cache add \
    shadow \
    screen \
    bash \
    gettext
 
RUN groupadd craftorio \
    && useradd -d /opt/craftorio -g craftorio -s /bin/bash -m craftorio \
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
COPY ultra-core/ultra-core-agent-java8.jar ultra-core-agent.jar

# Copy and map ultra-core config
COPY ultra-core/ultra-core-agent-server.conf.tpl ultra-core-agent-server.conf.tpl

# Copy forge installer
COPY server/forge/${MC_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar forge-installer.jar

# Install forge
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