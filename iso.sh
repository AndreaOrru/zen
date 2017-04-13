#!/bin/sh

cp zen run/iso/boot/
grub-mkrescue -o run/zen.iso run/iso/
