# Zen
Experimental operating system written in [Zig](http://ziglang.org).

## Build and test
To build the kernel, simply type:
```
zig build
```

You can run and debug the kernel straight away with Qemu:
```
# Run the kernel inside the emulator.
./qemu.sh

# Wait for a GDB connection first (for debugging).
./qemu.sh -g
gdb
```

You can also generate a bootable ISO and try it on Bochs (or on real hardware if you feel like it):
```
./iso.sh    # Generate run/zen.iso
./bochs.sh
```
