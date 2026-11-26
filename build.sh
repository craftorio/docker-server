#!/bin/bash
set -e
REPOSITORY=${REPOSITORY:-"ghcr.io/craftorio/docker-server-minecraft"}
pushd $(dirname $0) > /dev/null;DIR=$(pwd -P);popd > /dev/null
cd "${DIR}"
PUSH=${PUSH:-""}
while read tag; do
    if [ -z $1 ] || [[ $tag == $1* ]]; then 
        if [ -e "docker/${tag}/Dockerfile" ]; then
            if [ -e "docker/${tag}/HORIZON_COMMIT" ]; then
                # Horizon is built from the private craftorio/horizon at the pinned commit
                src="docker/${tag}/horizon-src"
                [ -d "$src/.git" ] || git clone -q git@github.com:craftorio/horizon.git "$src"
                git -C "$src" fetch -q origin && git -C "$src" checkout -q "$(cat "docker/${tag}/HORIZON_COMMIT")"
            fi
            docker build --build-arg HORIZON_GAME_BUILD_ID="$(cat "docker/${tag}/HORIZON_COMMIT" 2>/dev/null)" --add-host sessionserver.mojang.com:127.0.0.1 --add-host authserver.mojang.com:127.0.0.1 -t ${REPOSITORY}:${tag} -f "docker/${tag}/Dockerfile" ./docker
            if [[ -n $PUSH ]]; then
                docker push ${REPOSITORY}:${tag}
            fi
        fi
    fi
done < <(ls "docker")
