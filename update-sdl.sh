#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Need commit hash"
    exit 1
fi

rm -f $1.tar.gz
wget https://github.com/jack-ji/sdl.zig/archive/$1.tar.gz
zig fetch --save=sdl $1.tar.gz
sed -i "s/$1/https:\/\/github.com\/jack-ji\/sdl.zig\/archive\/&/" build.zig.zon
rm -f $1.tar.gz
