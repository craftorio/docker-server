# Dockerized Server

## Building Docker Images

To build a specific version:
```bash
./build.sh 1.19.2-arclight-1.0.6-forge-43.4.4
```

To build all available versions:
```bash
./build.sh
```

Available versions can be found in the `docker/` directory.

## Running the Server

Create the server work dir
```bash
mkdir ~/my-server
```

Navigate to the dir
```bash
cd ~/my-server
```

Create required dirs
```bash
mkdir -p \
    worlds \
    dynmap \
    mods \
    logs \
    plugins \
    config \
    config-server
```

Change ownership
```bash
chown -R 1000:1000 . 
```

Run the server
```bash
docker run -d \
    --name my-server \
    -e JVM_MEMORY_MAX=4096M \
    -p 25565:25565 \
    -v ${PWD}/worlds:/opt/craftorio/worlds \
    -v ${PWD}/mods:/opt/craftorio/mods \
    -v ${PWD}/logs:/opt/craftorio/logs \
    -v ${PWD}/plugins:/opt/craftorio/plugins \
    -v ${PWD}/config:/opt/craftorio/config \
    -v ${PWD}/config-server:/opt/craftorio/config-server \
    ghcr.io/craftorio/docker-server-minecraft:1.19.2-arclight-1.0.6-forge-43.4.4
```
