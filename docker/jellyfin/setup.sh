#!/bin/bash

docker run -d                                               \
    --name jellyfin                                         \
    --user 1000:1000                                        \
    --net=host                                              \
    --volume jellyfin-config:/config                        \
    --volume jellyfin-cache:/cache                          \
    --mount type=bind,source=/mnt/qnap_media,target=/media  \
    --restart=unless-stopped                                \
jellyfin/jellyfin


docker run -d                                                   \
    --name media_server                                         \
    --user 1000:1000                                            \
    --net=bridge                                                \
    --volume media-server-config:/config                        \
    --volume media-server-cache:/cache                          \
    --mount type=bind,source=/mnt/qnap_flin_media,target=/media \
    --restart=unless-stopped                                    \
    -p 8097:8096                                                \
jellyfin/jellyfin
