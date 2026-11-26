# Horizon: Minecraft 26.3 rewritten in Rust (no Java, no ultra-core agent). Build context: ./docker, with the
# sources of craftorio/horizon at the commit in HORIZON_COMMIT checked out into 26.3-horizon/horizon-src
# (the workflow and build.sh do it). Based on packaging/server/Dockerfile of that repository.
#
# The image holds none of Minecraft's files: mount the prepared resources (horizon/resources of the client
# bundle) read-only on /opt/horizon/.local/horizon-client/26.3. The server folder is the /opt/craftorio volume;
# the first start writes server.toml there from HORIZON_* (WORLD, SEED, PORT, WHITELIST, PLAYERS, OP), later
# starts use the file. Players log in through Craftorio's accounts: HORIZON_API_DISCOVERY.
FROM rust:1-slim-bookworm AS build
WORKDIR /src
COPY 26.3-horizon/horizon-src/ .
ARG HORIZON_GAME_BUILD_ID
# The server build of the game (no sound, no controllers: neither ALSA nor udev) as horizon-engine.
RUN cargo build --release --locked -p horizon-game --no-default-features --bin horizon-client \
    && cargo build --release --locked -p horizon-server --bin horizon-server \
    && mkdir /out && cp target/release/horizon-client /out/horizon-engine && cp target/release/horizon-server /out/

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 craftorio \
    && useradd -u 1000 -d /opt/craftorio -g craftorio -s /usr/sbin/nologin -m craftorio \
    && mkdir -p /opt/horizon/.local/horizon-client \
    && chown craftorio:craftorio /opt/craftorio
COPY --from=build /out/ /opt/horizon/

ENV PATH=/opt/horizon:$PATH \
    HORIZON_NO_AUDIO=1 \
    HORIZON_NO_UPDATE_CHECK=1 \
    HORIZON_EULA=true \
    HORIZON_WHITELIST=false \
    HORIZON_API_DISCOVERY=https://mc.craftorio.com/discovery/minecraft/client

USER craftorio
WORKDIR /opt/craftorio
VOLUME ["/opt/craftorio"]
EXPOSE 25565
# SIGTERM makes horizon-server save and stop the game cleanly: run with --stop-timeout 180.
CMD ["sh", "-c", "test -f server.toml || horizon-server init --yes || exit 1; exec horizon-server run"]
