#!/bin/sh

cp zen               run/iso/boot/
cp daemons/test/test run/iso/daemons/

grub-mkrescue -o run/zen.iso run/iso/
