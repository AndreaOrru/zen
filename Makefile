# Zig compiler flags.
ZIGFLAGS := -Doptimize=ReleaseSafe

# Artifacts paths.
ISO_DIR := iso_root
ISO_FILE := zen.iso
KERNEL_BIN := kernel/zig-out/bin/kernel

# Default target.
.PHONY: all
all: $(ISO_FILE)

# Download and build the Limine bootloader.
boot/limine:
	git clone https://github.com/limine-bootloader/limine.git \
		--branch=v8.x-binary --depth=1                        \
		boot/limine
	$(MAKE) -C boot/limine

# Build the kernel binary.
.PHONY: kernel
kernel:
	cd kernel && zig build $(ZIGFLAGS)

# Create a bootable ISO image.
$(ISO_FILE): boot/limine kernel
	rm -rf $(ISO_DIR)               # Delete the existing temporary ISO directory.
	mkdir -p $(ISO_DIR)/EFI/BOOT    # Create the necessary directory structure.

	cp boot/limine.conf $(ISO_DIR)  # Copy the Limine bootloader configuration file.
	cp $(KERNEL_BIN) $(ISO_DIR)     # Copy the kernel binary.

	cp boot/limine/limine-bios.sys    \
	   boot/limine/limine-bios-cd.bin \
	   boot/limine/limine-uefi-cd.bin \
	   $(ISO_DIR)  # Copy the Limine bootloader binaries.
	cp boot/limine/BOOTX64.EFI        \
	   boot/limine/BOOTIA32.EFI       \
	   $(ISO_DIR)/EFI/BOOT/  # Copy the UEFI binaries.

	xorriso -as mkisofs -R -r -J -b limine-bios-cd.bin                \
			-no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
			-apm-block-size 2048 --efi-boot limine-uefi-cd.bin        \
			-efi-boot-part --efi-boot-image --protective-msdos-label  \
			$(ISO_DIR) -o $(ISO_FILE)  # Create the bootable ISO image.

	./boot/limine/limine bios-install $(ISO_FILE)  # Install Limine.
	rm -rf $(ISO_DIR)                              # Clean up directory.

# Run the ISO image in QEMU.
.PHONY: run
run: $(ISO_FILE)
	qemu-system-x86_64 -M q35 -m 128M -cdrom $(ISO_FILE) -boot d

# Clean up build artifacts.
.PHONY: clean
clean:
	rm -rf $(ISO_DIR) $(ISO_FILE)
	rm -rf kernel/.zig-cache kernel/zig-out

# Clean up everything.
.PHONY: distclean
distclean: clean
	rm -rf boot/limine
