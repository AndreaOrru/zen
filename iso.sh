#!/bin/sh

cp zen                       run/iso/boot/
cp servers/receiver/receiver run/iso/servers/
cp servers/sender/sender     run/iso/servers/

grub-mkrescue -o run/zen.iso run/iso/
