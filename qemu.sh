#!/bin/sh

if [ "$1" = "-g" ]; then
    qemu-system-i386 -display curses -s -S -kernel zen
else
    qemu-system-i386 -display curses -kernel zen
fi
