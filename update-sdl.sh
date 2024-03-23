#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Need commit hash"
    exit 1
fi

rm -f $1.tar.gz
wget https://github.com/jack-ji/sdl.zig/archive/$1.tar.gz
zig fetch --save=sdl $1.tar.gz
rm -f $1.tar.gz
