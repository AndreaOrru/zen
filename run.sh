docker compose up --build
qemu-system-i386 -display curses -kernel zen -initrd servers/keyboard/keyboard,servers/terminal/terminal,servers/shell/shell
