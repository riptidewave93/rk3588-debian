#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 04_post_docker.sh"

if [ -d ${build_path}/final ]; then
    debug_msg "WARNING: final builddir already exists! Cleaning up..."
    rm -rf ${build_path}/final
fi
mkdir -p ${build_path}/final

# Kick off the docker to do the magics for us, since we need genimage
docker run --rm -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/run_package_final.sh

debug_msg "Finished 04_post_docker.sh"
