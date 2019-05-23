@echo off

pushd src
    md ..\build 2>nul
    nasm -f bin dump.asm -o ../build/dump.bin   
popd