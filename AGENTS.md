# AGENTS.md

## Project Purpose

This repository builds and publishes Docker images for Minecraft servers. Most changes fall into one of three areas:

- versioned images in `docker/<version>/Dockerfile`
- shared runtime scripts in `docker/entrypoint.sh` and `docker/java-jar-launcher.sh`
- release automation in `.github/workflows/build-docker-server.yml`

## Repo Map

- `README.md`: user-facing run, volume, and environment-variable docs
- `build.sh`: local image build helper; can build one tag or all tags
- `docker/<tag>/Dockerfile`: one image definition per supported server version
- `docker/entrypoint.sh`: first-start initialization, config symlinks, screen lifecycle
- `docker/java-jar-launcher.sh`: JVM launch flags and optional Xvfb setup
- `docker/ultra-core/`: auth/session rewrite template and bundled agent assets

## Change Rules

- Keep shared behavior in the common scripts when possible; avoid duplicating logic across Dockerfiles.
- Treat version-specific Dockerfile differences as intentional. If you change one Arclight image, check whether the same change belongs in the other versioned Dockerfiles too.
- When adding or removing a supported version, update all of these together: `docker/<tag>/Dockerfile`, the workflow matrix in `.github/workflows/build-docker-server.yml`, and the supported-version docs in `README.md`.
- Preserve the container data layout under `/opt/craftorio` unless the user explicitly asks for a breaking change. The mounted directories documented in `README.md` are part of the external interface.
- Preserve existing environment variable names such as `JVM_MEMORY_MAX`, `JVM_MEMORY_START`, `MC_AUTH_SERVER`, and `MC_AUTH_SESSION_SERVER` unless the change also includes documentation and migration guidance.
- Be careful with startup and shutdown flow in `docker/entrypoint.sh`; it handles first-run initialization, config migration into `config-server`, and graceful stop behavior.

## Validation

- For docs-only changes, verify the referenced paths, tags, env vars, and commands match the repository.
- For script or Dockerfile changes, prefer targeted verification first by reviewing related files for consistency.
- Full image builds are expensive. Only run Docker builds when the user asks or when verification requires it. If you do, prefer `./build.sh <tag>` over building every image.

## Notes For Agents

- This is a small repo; read the relevant files before making broad changes.
- Favor minimal edits that keep README examples, workflow tags, and Docker image contents in sync.
