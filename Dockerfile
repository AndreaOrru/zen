# Use Ubuntu 16.04 as base image (Xenial Xerus)
FROM ubuntu:16.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /zig

# Download prebuilt Zig 0.10.1 for Linux x86_64
RUN wget https://ziglang.org/download/0.3.0/zig-linux-x86_64-0.3.0.tar.xz

# Extract the tarball
RUN tar -xJf zig-linux-x86_64-0.3.0.tar.xz

# Create directory for projects
RUN mkdir -p /project

# Add Zig to PATH
ENV PATH="/zig/zig-linux-x86_64-0.3.0:${PATH}"

# Set working directory to /project for mounted volumes
WORKDIR /project

# Set default command
CMD ["zig", "build"]