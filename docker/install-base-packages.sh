#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    screen \
    bash \
    gettext-base \
    fontconfig \
    fonts-dejavu-core \
    fonts-liberation \
    xvfb \
    ca-certificates

rm -rf /var/lib/apt/lists/*
fc-cache -fv
