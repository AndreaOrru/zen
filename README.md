# Zen [![Build Status](https://travis-ci.org/AndreaOrru/zen.svg?branch=master)](https://travis-ci.org/AndreaOrru/zen)
Experimental operating system written in [Zig](http://ziglang.org).

## Build and test
To build the kernel, simply type:
```
zig build
```

You can run and debug the kernel straight away with Qemu:
```
# Run the kernel inside the emulator.
zig build qemu

# Wait for a GDB connection first (for debugging).
zig build qemu-debug
gdb
```

You can also generate a bootable ISO and try it on Bochs (or on real hardware if you feel like it):
```
./iso.sh    # Generate run/zen.iso
./bochs.sh
```
