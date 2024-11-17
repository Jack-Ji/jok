#!/bin/bash

function latest_hash() {
    git ls-remote -h $1 | grep '\<main\>' | awk '{print $1}'
}

function update_dep_remote() {
    url=$1
    name=`basename $url`
    hash=`latest_hash $url`

    rm -f $name.tar.gz
    wget -c --show-progress $url/archive/$hash.tar.gz
    zig fetch --save=$name $hash.tar.gz
    depurl=`echo "git+$url.git#$hash" | sed 's@/@\\\/@g'`
    sed -i "s/$hash\.tar\.gz/$depurl/" build.zig.zon
    rm -f $name.tar.gz
}

function update_dep_local() {
    url=$1
    name=${url##*/}
    rm -rf deps/$name
    if git clone --depth 1 $url deps/$name; then
        rm -rf deps/$name/.*
        return
    fi
    echo "Failed to clone $url"
    exit
}

update_dep_local https://github.com/zig-gamedev/system_sdk
update_dep_local https://github.com/zig-gamedev/zaudio
update_dep_local https://github.com/zig-gamedev/zgui
update_dep_local https://github.com/zig-gamedev/zmath
update_dep_local https://github.com/zig-gamedev/zmesh
update_dep_local https://github.com/zig-gamedev/znoise
update_dep_local https://github.com/zig-gamedev/ztracy

rm -f *.tar.gz
