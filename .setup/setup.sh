#!/bin/bash

DOTFILES="${HOME}/.dotfiles"

# WIP!

function setup_docker() {
    local docker_dir="${HOME}/docker"

    if [ ! -d $docker_dir ]; then
        mkdir $dockerdir
    fi

    mkdir "${docker_dir}/nginx-proxy-manager"
    
    # symlink docker-compose files
    ln -s "${DOTFILES}/docker/docker-compose/nginx-proxy-manager.yml" "${docker_dir}/nginx-proxy-manager/docker-compose.yml"
}
