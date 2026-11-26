# 🚀 Docker Minecraft Server

[![Build Multi-Arch Images](https://github.com/craftorio/docker-server/actions/workflows/build-docker-server.yml/badge.svg)](https://github.com/craftorio/docker-server/actions/workflows/build-docker-server.yml)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-container%20registry-blue?logo=github)](https://github.com/craftorio/docker-server/pkgs/container/docker-server-minecraft)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-multi--arch-blue?logo=docker)](https://github.com/craftorio/docker-server)

> 🐳 **Multi-architecture Docker images** for Minecraft servers with **Forge**, **NeoForge**, and **Arclight** support

---

## ✨ Features

- 🏗️ **Multi-platform support**: AMD64 & ARM64
- ⚡ **Optimized performance** with built-in caching
- 🔧 **Multiple Minecraft versions** (Forge + NeoForge + Arclight)
- 🔄 **Automatic builds** via GitHub Actions
- 📦 **Published to GitHub Container Registry**
- 🛡️ **Production-ready** configurations
- 🎯 **Resource packs & Data packs**: Built-in support for Minecraft resource packs, data packs, and mod-specific packs (Flan's Mod & TaCZ)

## 🎮 Supported Versions

| Version | Type | Java | Minecraft | Forge / NeoForge | Arclight |
|---------|------|------|-----------|------------------|----------|
| `1.12.2-forge-14.23.5.2860` | Forge | 8 | 1.12.2 | 14.23.5.2860 | - |
| `1.18.2-arclight-1.0.12-forge-40.2.14` | Arclight | 17 | 1.18.2 | 40.2.14 | 1.0.12 |
| `1.19.2-arclight-1.0.6-forge-43.4.4` | Arclight | 17 | 1.19.2 | 43.4.4 | 1.0.6 |
| `1.19.4-arclight-1.0.8-forge-45.2.6` | Arclight | 17 | 1.19.4 | 45.2.6 | 1.0.8 |
| `1.20.1-forge-47.4.18` | Forge | 17 | 1.20.1 | 47.4.18 | - |
| `1.20.1-arclight-1.0.6-forge-47.4.18` | Arclight | 17 | 1.20.1 | 47.4.18 | 1.0.6-SNAPSHOT |
| `1.21.1-neoforge-21.1.266` | NeoForge | 21 | 1.21.1 | 21.1.266 | - |
| `26.3-horizon` | Horizon (Rust) | - | 26.3 | - | - |

### Horizon (`26.3-horizon`)

Minecraft 26.3 rewritten in Rust, built from the private `craftorio/horizon` at the commit in
`docker/26.3-horizon/HORIZON_COMMIT` (the workflow checks it out with the `HORIZON_DEPLOY_KEY` deploy key). It is
not a Java image: no JVM variables, no ultra-core agent, its own layout. The image holds none of Minecraft's
files: mount the prepared resources (`horizon/resources` of the client bundle) read-only.

```bash
docker run -d --name horizon -p 25565:25565 --stop-timeout 180 \
  -v horizon-data:/opt/craftorio \
  -v /srv/horizon/resources:/opt/horizon/.local/horizon-client/26.3:ro \
  -e HORIZON_OP=Steve \
  ghcr.io/craftorio/docker-server-minecraft:26.3-horizon
```

| Variable | Default | Description |
|----------|---------|-------------|
| `HORIZON_API_DISCOVERY` | `https://mc.craftorio.com/discovery/minecraft/client` | Services discovery document (accounts, joins) |
| `HORIZON_WHITELIST` | `false` | First start only: whitelist on or off |
| `HORIZON_WORLD`, `HORIZON_SEED`, `HORIZON_PORT`, `HORIZON_PLAYERS`, `HORIZON_OP` | | First start only: answers for `horizon-server init` |

The first start writes `server.toml` into `/opt/craftorio`; edit it there afterwards. Manage the server with
`docker exec horizon horizon-server status|cmd|backup|logs`. The `latest` tag never points at this image.

Mods: put `<id>.hmod` into `horizon-mods/` of `/opt/craftorio` and turn each on with a line `mod.<id>:true` in
`/opt/craftorio/horizon-mods.txt`, then restart. Players join only with exactly the server's mods: Craftorio's
launcher ships the client's (`apps/horizon-mods` of craftorio-launcher), so both change together. The image has
the WebAssembly standard library the game needs for wasm mods (`/opt/horizon/horizon-wasm-std.wasm`).

## 🚀 Quick Start

### 1. 📁 Prepare Server Directory

```bash
# Create server directory
mkdir ~/my-minecraft-server && cd ~/my-minecraft-server

# Create required directories
mkdir -p world dynmap mods logs plugins config config-server Flan tacz resourcepacks datapacks

# Set permissions (Linux/macOS)
chown -R 1000:1000 .
```

### 2. 🎯 Run Server

```bash
docker run -d \
  --name minecraft-server \
  --restart unless-stopped \
  --dns 8.8.8.8 \
  -e JVM_MEMORY_MAX=4096M \
  -p 12565:25565 \
  -v ${PWD}/world:/opt/craftorio/world \
  -v ${PWD}/mods:/opt/craftorio/mods \
  -v ${PWD}/logs:/opt/craftorio/logs \
  -v ${PWD}/plugins:/opt/craftorio/plugins \
  -v ${PWD}/config:/opt/craftorio/config \
  -v ${PWD}/config-server:/opt/craftorio/config-server \
  -v ${PWD}/Flan:/opt/craftorio/Flan \
  -v ${PWD}/tacz:/opt/craftorio/tacz \
  -v ${PWD}/resourcepacks:/opt/craftorio/resourcepacks \
  -v ${PWD}/datapacks:/opt/craftorio/datapacks \
  ghcr.io/craftorio/docker-server-minecraft:1.20.1-arclight-1.0.6-forge-47.4.18
```

### 3. 📊 Monitor Server

```bash
# View logs
docker logs -f minecraft-server

# Connect to Minecraft console (recommended)
docker exec -it minecraft-server screen -r

# Access server bash shell
docker exec -it minecraft-server bash

# Stop server
docker stop minecraft-server
```

> 💡 **Tip**: Use `docker exec -it minecraft-server screen -r` to connect directly to the Minecraft server console where you can run server commands like `/op`, `/whitelist`, `/say`, etc. Press `Ctrl+A` then `Ctrl+D` to detach from console without stopping the server.

## 🎨 Resource Packs & Data Packs

### 📦 Resource Packs
Place your custom resource packs in the `resourcepacks/` folder to:
- **Change textures, sounds, and models** 
- **Customize UI elements and fonts**
- **Add custom music and sound effects**

### 📊 Data Packs  
Place your data packs in the `datapacks/` folder to:
- **Add custom recipes and loot tables**
- **Create custom dimensions and biomes** 
- **Implement custom game mechanics**
- **Add new structures and features**

### 🔧 Mod-Specific Packs
- **Flan/**: Resource packs for Flan's Mod vehicles and weapons
- **tacz/**: Resource packs for TaCZ (Timeless and Classics Zero) mod

> 💡 **Tip**: Resource packs are applied client-side, while data packs affect server-side gameplay. Both are automatically loaded when placed in their respective folders.

## 🔧 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `JVM_MEMORY_MAX` | `2048M` | Maximum JVM heap size |
| `JVM_MEMORY_MIN` | `1024M` | Minimum JVM heap size |
| `JVM_GC` | `g1` | Garbage collector: `g1` or `shenandoah` (Java 17+ images only) |
| `MC_AUTH_SERVER` | `auth.craftorio.com` | Authentication server |
| `MC_AUTH_SESSION_SERVER` | `sessionserver.craftorio.com` | Session server |
| `INIT_TIMEOUT` | `600s` | First-start initialization timeout |
| `INIT_TIMEOUT_SECONDS` | `600` | Same timeout in seconds for startup progress checks |

## 🐳 Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  minecraft:
    image: ghcr.io/craftorio/docker-server-minecraft:1.20.1-arclight-1.0.6-forge-47.4.18
    container_name: minecraft-server
    restart: unless-stopped
    ports:
      - "25565:25565"
    environment:
      - JVM_MEMORY_MAX=4096M
      - JVM_MEMORY_MIN=2048M
    volumes:
      - ./world:/opt/craftorio/world
      - ./mods:/opt/craftorio/mods
      - ./logs:/opt/craftorio/logs
      - ./plugins:/opt/craftorio/plugins
      - ./config:/opt/craftorio/config
      - ./config-server:/opt/craftorio/config-server
      - ./Flan:/opt/craftorio/Flan
      - ./tacz:/opt/craftorio/tacz
      - ./resourcepacks:/opt/craftorio/resourcepacks
      - ./datapacks:/opt/craftorio/datapacks
    stdin_open: true
    tty: true
```

Run with:
```bash
docker-compose up -d
```

## 🛠️ Building Images Locally

### Prerequisites
- Docker with Buildx support
- Multi-platform build capability

### Build specific version:
```bash
./build.sh 1.20.1-arclight-1.0.6-forge-47.4.18
```

### Build all versions:
```bash
./build.sh
```

### Push to registry:
```bash
PUSH=1 ./build.sh
```

## 🔍 Troubleshooting

### Server won't start
- Check memory allocation: `docker logs minecraft-server`
- Verify port availability: `netstat -tulpn | grep 25565`
- Ensure proper file permissions

### Performance issues
- Increase memory: `-e JVM_MEMORY_MAX=8192M`
- Use SSD storage for volumes
- Monitor with: `docker stats minecraft-server`

### Connection problems
- Check firewall settings
- Verify port mapping: `-p 25565:25565`
- Test with: `telnet localhost 25565`

## 📁 Volume Structure

```
📂 Server Directory/
├── 🌍 world/          # World saves
├── 🗺️ dynmap/         # Dynmap web files
├── 📦 mods/           # Forge mods
├── 📝 logs/           # Server logs
├── 🔌 plugins/        # Bukkit/Spigot plugins
├── ⚙️ config/         # Configuration files
├── 🔧 config-server/  # Server-specific configs
├── 🎯 Flan/           # Flan's Mod resource packs
├── 🔫 tacz/           # TaCZ mod resource packs
├── 🎨 resourcepacks/  # Minecraft resource packs
└── 📊 datapacks/      # Minecraft data packs
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- 📦 [GitHub Container Registry](https://github.com/craftorio/docker-server/pkgs/container/docker-server-minecraft)
- 🔧 [Issues & Support](https://github.com/craftorio/docker-server/issues)
- 📚 [Documentation](https://github.com/craftorio/docker-server/wiki)

---

<div align="center">

**Made with ❤️ by [Craftorio](https://github.com/craftorio)**

*Happy Mining! ⛏️*

</div>
