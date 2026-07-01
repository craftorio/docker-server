FROM azul/zulu-openjdk:17-jre AS base

COPY install-base-packages.sh /tmp/install-base-packages.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    chmod +x /tmp/install-base-packages.sh && /tmp/install-base-packages.sh && rm /tmp/install-base-packages.sh

RUN groupadd -g 1000 craftorio \
    && useradd -u 1000 -d /opt/craftorio -g craftorio -s /bin/bash -m craftorio \
    && mkdir -p /opt/craftorio \
    && chown craftorio:craftorio /opt/craftorio

FROM base AS builder
USER craftorio

ARG MC_VERSION=1.20.1
ARG FORGE_VERSION=47.4.18

WORKDIR /opt/craftorio

COPY --chown=craftorio:craftorio --chmod=0700 java-jar-launcher.sh java-jar-launcher.sh
COPY --chown=craftorio:craftorio --chmod=0700 java-forge-launcher.sh java-forge-launcher.sh
COPY --chown=craftorio:craftorio --chmod=0700 jvm-gc-args.sh jvm-gc-args.sh
COPY --chown=craftorio:craftorio ultra-core/ultra-core-agent-java17.jar ultra-core-agent.jar
COPY --chown=craftorio:craftorio ultra-core/ultra-core-agent-server.conf.tpl ultra-core-agent-server.conf.tpl
COPY --chown=craftorio:craftorio server/forge/${MC_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar forge-installer.jar

RUN java -jar forge-installer.jar --installServer \
    && rm forge-installer.jar \
    && chmod +x run.sh

RUN echo "eula=true" > eula.txt && \
    export JVM_MEMORY_START=1024M && export JVM_MEMORY_MAX=2048M && \
    timeout 180s ./java-forge-launcher.sh nogui 2>&1 | tee /tmp/forge-cache.log & \
    timeout 180s bash -c "until grep -E '(Done.*For help|Server started|Finished loading)' /tmp/forge-cache.log 2>/dev/null; do sleep 2; done" && \
    echo "Forge libraries cached successfully" && \
    pkill -f "java-forge-launcher.sh" || true && \
    sleep 2 && \
    rm -rf world world_nether world_the_end && \
    find /opt/craftorio -name "*.log" -type f -delete 2>/dev/null || true && \
    echo "Cleaned up all log files"

RUN bash -c 'mkdir -p config-server.defaults && shopt -s nullglob && \
    for f in server.properties banned-ips.json banned-players.json ops.json whitelist.json *.yml *.conf; do \
      [[ "$(basename "$f")" == "ultra-core-agent-server.conf.tpl" ]] && continue; \
      [[ -f "$f" ]] && mv "$f" config-server.defaults/; \
    done'

RUN mkdir -p \
    /opt/craftorio/world \
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

ENV MC_AUTH_SERVER=auth.craftorio.com
ENV MC_AUTH_SESSION_SERVER=sessionserver.craftorio.com

COPY --from=builder --chown=craftorio:craftorio /opt/craftorio/ /opt/craftorio/
COPY --chown=craftorio:craftorio --chmod=0700 entrypoint.sh /entrypoint.sh

VOLUME ["/opt/craftorio/dynmap", "/opt/craftorio/world", "/opt/craftorio/plugins", "/opt/craftorio/mods", "/opt/craftorio/config", "/opt/craftorio/logs", "/opt/craftorio/config-server", "/opt/craftorio/scripts", "/opt/craftorio/Flan", "/opt/craftorio/tacz", "/opt/craftorio/resourcepacks", "/opt/craftorio/datapacks"]

EXPOSE 25565

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "server_start" ]
