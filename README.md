# 🚀 Docker Minecraft Server

[![Build Multi-Arch Images](https://github.com/craftorio/docker-server/actions/workflows/build-docker-server.yml/badge.svg)](https://github.com/craftorio/docker-server/actions/workflows/build-docker-server.yml)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-container%20registry-blue?logo=github)](https://github.com/craftorio/docker-server/pkgs/container/docker-server-minecraft)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-multi--arch-blue?logo=docker)](https://github.com/craftorio/docker-server)

> 🐳 **Multi-architecture Docker images** for Minecraft servers with **Forge** and **Arclight** support

---

## ✨ Features

- 🏗️ **Multi-platform support**: AMD64 & ARM64
- ⚡ **Optimized performance** with built-in caching
- 🔧 **Multiple Minecraft versions** (Forge + Arclight)
- 🔄 **Automatic builds** via GitHub Actions
- 📦 **Published to GitHub Container Registry**
- 🛡️ **Production-ready** configurations
- 🎯 **Resource packs & Data packs**: Built-in support for Minecraft resource packs, data packs, and mod-specific packs (Flan's Mod & TaCZ)

## 🎮 Supported Versions

| Version | Type | Java | Minecraft | Forge | Arclight |
|---------|------|------|-----------|-------|----------|
| `1.12.2-forge-14.23.5.2860` | Forge | 8 | 1.12.2 | 14.23.5.2860 | - |
| `1.18.2-arclight-1.0.12-forge-40.2.14` | Arclight | 17 | 1.18.2 | 40.2.14 | 1.0.12 |
| `1.19.2-arclight-1.0.6-forge-43.4.4` | Arclight | 17 | 1.19.2 | 43.4.4 | 1.0.6 |
| `1.19.4-arclight-1.0.8-forge-45.2.6` | Arclight | 17 | 1.19.4 | 45.2.6 | 1.0.8 |
| `1.20.1-arclight-1.0.6-forge-47.3.22` | Arclight | 17 | 1.20.1 | 47.3.22 | 1.0.6 |

## 🚀 Quick Start

### 1. 📁 Prepare Server Directory

```bash
# Create server directory
mkdir ~/my-minecraft-server && cd ~/my-minecraft-server

# Create required directories
mkdir -p worlds dynmap mods logs plugins config config-server Flan tacz resourcepacks datapacks

# Set permissions (Linux/macOS)
chown -R 1000:1000 .
```

### 2. 🎯 Run Server

```bash
docker run -d \
  --name minecraft-server \
  --restart unless-stopped \
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
  ghcr.io/craftorio/docker-server-minecraft:1.20.1-arclight-1.0.6-forge-47.3.22
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
| `MC_AUTH_SERVER` | `auth.craftorio.com` | Authentication server |
| `MC_AUTH_SESSION_SERVER` | `sessionserver.craftorio.com` | Session server |

## 🐳 Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  minecraft:
    image: ghcr.io/craftorio/docker-server-minecraft:1.20.1-arclight-1.0.6-forge-47.3.22
    container_name: minecraft-server
    restart: unless-stopped
    ports:
      - "25565:25565"
    environment:
      - JVM_MEMORY_MAX=4096M
      - JVM_MEMORY_MIN=2048M
    volumes:
      - ./worlds:/opt/craftorio/worlds
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
./build.sh 1.20.1-arclight-1.0.6-forge-47.3.22
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
├── 🌍 worlds/         # World saves
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
