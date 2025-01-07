# Use an official Ubuntu 22.04 base image
FROM ubuntu:22.04

# Set non-interactive mode for apt to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools and Docker
RUN apt-get update && apt-get install -y \
    nano \
    screen \
    curl \
    wget \
    htop \
    docker.io \
    openssh-server \
    xfce4 xfce4-goodies novnc python3-websockify python3-numpy tightvncserver openssl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
