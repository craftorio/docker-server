# Docker Caching Strategies for GitHub Actions

## Текущая настройка (уже реализована)
```yaml
cache-from: |
  type=gha
  type=registry,ref=ghcr.io/owner/docker-server-minecraft:cache-${{ matrix.version }}
cache-to: |
  type=gha,mode=max
  type=registry,ref=ghcr.io/owner/docker-server-minecraft:cache-${{ matrix.version }},mode=max
```

## Дополнительные стратегии кеширования

### 1. Build Secrets для приватных зависимостей
```yaml
- name: Build with secrets
  uses: docker/build-push-action@v5
  with:
    secrets: |
      "maven_token=${{ secrets.MAVEN_TOKEN }}"
    # кеширование работает и с секретами
```

### 2. Cache Mount для больших загрузок
В Dockerfile можно использовать:
```dockerfile
# Кеширование Maven зависимостей
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean install

# Кеширование APK пакетов
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache package
```

### 3. Multi-stage build optimization
```dockerfile
# Уже используется в вашем Dockerfile!
FROM azul/zulu-openjdk-alpine:17-jre AS base
# ... базовые пакеты

FROM base AS builder  
# ... сборка

FROM base
# ... финальный образ
```

### 4. Условное кеширование для PR
```yaml
cache-from: |
  type=gha
  ${{ github.event_name == 'pull_request' && 'type=registry,ref=ghcr.io/owner/repo:cache-pr' || '' }}
```

## Мониторинг эффективности кеша

### Добавление метрик в workflow:
```yaml
- name: Cache metrics
  run: |
    echo "Cache hit ratio: $(docker buildx imagetools inspect --format '{{.Manifest}}' cache-image || echo 'Cache miss')"
```

## Рекомендации для вашего проекта

1. ✅ **Уже настроено**: GHA + Registry cache
2. 🔄 **Можно добавить**: Cache mounts в Dockerfile для APK/Maven
3. 🔄 **Можно добавить**: Отдельные cache ключи для разных архитектур
4. 🔄 **Можно добавить**: Cleanup старых cache образов

## Примерные улучшения времени сборки
- **Без кеша**: 15-20 минут (полная сборка + библиотеки Minecraft)
- **С GHA cache**: 8-12 минут
- **С Registry cache**: 5-8 минут
- **С Cache mounts**: 3-5 минут

## Отладка кеша
```yaml
- name: Debug cache
  run: |
    docker buildx build --progress=plain --no-cache .
```
