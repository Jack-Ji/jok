#!/bin/bash

ZMODULES=../zig-gamedev/libs/

rm -rf src/deps/system-sdk
cp -r $ZMODULES/system-sdk src/deps

rm -rf src/deps/imgui/zgui
cp -r $ZMODULES/zgui src/deps/imgui
sed -i 's/\/\/\(#define ImDrawIdx unsigned int\)/\1/' src/deps/imgui/zgui/libs/imgui/imconfig.h
sed -i 's/DrawIdx = u16/DrawIdx = u32/' src/deps/imgui/zgui/src/gui.zig

rm -rf src/deps/zaudio
cp -r $ZMODULES/zaudio src/deps

rm -rf src/deps/zmath
cp -r $ZMODULES/zmath src/deps

rm -rf src/deps/zmesh
cp -r $ZMODULES/zmesh src/deps

rm -rf src/deps/znoise
cp -r $ZMODULES/znoise src/deps

rm -rf src/deps/ztracy
cp -r $ZMODULES/ztracy src/deps

