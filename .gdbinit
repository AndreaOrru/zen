set disassembly-flavor intel

file zen
target remote localhost:1234

break _start
continue

tui enable
