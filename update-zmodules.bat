set ZMODULES=../zig-gamedev/libs

rm -rf src/deps/system-sdk
cp -r %ZMODULES%/system-sdk src/deps

rm -rf src/deps/zaudio
cp -r %ZMODULES%/zaudio src/deps

rm -rf src/deps/zmath
cp -r %ZMODULES%/zmath src/deps

rm -rf src/deps/zmesh
cp -r %ZMODULES%/zmesh src/deps

rm -rf src/deps/znoise
cp -r %ZMODULES%/znoise src/deps

rm -rf src/deps/zpool
cp -r %ZMODULES%/zpool src/deps

rm -rf src/deps/ztracy
cp -r %ZMODULES%/ztracy src/deps

rm -rf src/deps/imgui/zgui
cp -r %ZMODULES%/zgui src/deps/imgui

