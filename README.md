# Docker Server

Create the server work dir
```bash
mkdir ~/my-saerver
```

Navigate to the dir
```bash
cd ~/my-saerver
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
    -e JVM_MEMORY_MAX=2048M \
    -p 25565:25565
    -v ${PWD}/worlds:/opt/craftorio/worlds \
    -v ${PWD}/mods:/opt/craftorio/mods \
    -v ${PWD}/logs:/opt/craftorio/logs \
    -v ${PWD}/plugins:/opt/craftorio/plugins \
    -v ${PWD}/config:/opt/craftorio/config \
    -v ${PWD}/config-server:/opt/craftorio/config-server \
    craftorio/docker-server:1.19.4-arclight-1.0.8-forge-45.2.6
```