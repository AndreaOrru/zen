#!/bin/sh

cp zen                       run/iso/boot/
cp servers/terminal/terminal run/iso/servers/
cp servers/keyboard/keyboard run/iso/servers/

grub-mkrescue -o run/zen.iso run/iso/
