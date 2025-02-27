#!/bin/bash
set -e
REPOSITORY=${REPOSITORY:-"craftorio/docker-server"}
pushd $(dirname $0) > /dev/null;DIR=$(pwd -P);popd > /dev/null
cd "${DIR}"
PUSH=${PUSH:-""}
while read tag; do
    if [ -z $1 ] || [[ $tag == $1* ]]; then 
        if [ -e "dockerfile/${tag}/Dockerfile" ]; then
            docker build --add-host sessionserver.mojang.com:127.0.0.1 --add-host authserver.mojang.com:127.0.0.1 -t ${REPOSITORY}:${tag} -f "dockerfile/${tag}/Dockerfile" .
            if [[ -n $PUSH ]]; then
                docker push ${REPOSITORY}:${tag}
            fi
        fi
    fi
done < <(ls "dockerfile")