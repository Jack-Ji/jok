#!/bin/bash

ZMODULES=../zig-gamedev/libs/

rm -rf deps/system-sdk
cp -r $ZMODULES/system-sdk deps

rm -rf deps/imgui/zgui
cp -r $ZMODULES/zgui deps/imgui
sed -i 's/\/\/\(#define ImDrawIdx unsigned int\)/\1/' deps/imgui/zgui/libs/imgui/imconfig.h
sed -i 's/DrawIdx = u16/DrawIdx = u32/' deps/imgui/zgui/src/gui.zig

rm -rf deps/zaudio
cp -r $ZMODULES/zaudio deps

rm -rf deps/zmath
cp -r $ZMODULES/zmath deps

rm -rf deps/zmesh
cp -r $ZMODULES/zmesh deps

rm -rf deps/znoise
cp -r $ZMODULES/znoise deps

rm -rf deps/ztracy
cp -r $ZMODULES/ztracy deps

