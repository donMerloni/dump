@echo off

call build
qemu-system-i386 -drive file=build/dump.bin,format=raw -monitor stdio