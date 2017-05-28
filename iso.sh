#!/bin/sh

cp zen                       run/iso/boot/
cp daemons/receiver/receiver run/iso/daemons/
cp daemons/sender/sender     run/iso/daemons/

grub-mkrescue -o run/zen.iso run/iso/
