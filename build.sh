#!/bin/bash

# Build Script for ROM
# Supported targets: a52q, a52sxq, a52xq, a71, a72q, a73xq, b0q, dm1q, dm2q, dm3q, g0q, m52xq, r0q, r8q, r9q, r9q2

# Fail on error
set -e

# Ensure a target is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <target>"
  echo "Supported targets: a52q, a52sxq, a52xq, a71, a72q, a73xq, b0q, dm1q, dm2q, dm3q, g0q, m52xq, r0q, r8q, r9q, r9q2"
  exit 1
fi

TARGET=$1

# Global setup
function setup_environment() {
  echo ">>> Updating and installing dependencies"
  sudo apt update
  DEBIAN_FRONTEND=noninteractive sudo apt install -yq \
    attr ccache clang ffmpeg golang \
    libbrotli-dev libgtest-dev libprotobuf-dev libunwind-dev libpcre2-dev \
    libzstd-dev linux-modules-extra-$(uname -r) lld protobuf-compiler webp \
    zipalign

  # Load required kernel modules
  sudo modprobe erofs f2fs

  echo ">>> Setting up git user"
  git config --global user.name "local-build"
  git config --global user.email "localbuild@noreply.local"

  # Decode platform keys if required
  if [ -n "$PLATFORM_KEY_PK8" ] && [ -n "$PLATFORM_KEY_PEM" ]; then
    echo ">>> Decoding platform keys"
    echo -n "$PLATFORM_KEY_PK8" | base64 --decode > unica/security/unica_platform.pk8
    echo -n "$PLATFORM_KEY_PEM" | base64 --decode > unica/security/unica_platform.x509.pem
  fi

  echo ">>> Environment setup complete"
}

# Set up Java
function setup_java() {
  echo ">>> Setting up JDK 11"
  sudo apt install -y openjdk-11-jdk
  export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
  export PATH="$JAVA_HOME/bin:$PATH"
}

# Set up Node.js
function setup_node() {
  echo ">>> Setting up Node.js"
  curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
  sudo apt install -y nodejs
}

# Free up disk space
function free_disk_space() {
  echo ">>> Freeing up disk space"
  sudo apt-get clean
  sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc
}

# Build dependencies
function build_dependencies() {
  echo ">>> Building dependencies for target: $TARGET"
  source ./buildenv.sh "$TARGET"
}

# Download stock firmwares
function download_stock_fw() {
  echo ">>> Downloading stock firmwares for target: $TARGET"
  source ./buildenv.sh "$TARGET"
  ./scripts/download_fw.sh
}

# Extract stock firmwares
function extract_stock_fw() {
  echo ">>> Extracting stock firmwares for target: $TARGET"
  source ./buildenv.sh "$TARGET"
  ./scripts/extract_fw.sh
  ./scripts/cleanup.sh odin
}

# Build the ROM
function build_rom() {
  echo ">>> Building ROM for target: $TARGET"
  source ./buildenv.sh "$TARGET"
  ./scripts/make_rom.sh --no-rom-zip # --no-rom-tar
}

# Main Execution
function main() {
  setup_environment
  setup_java
  setup_node
  free_disk_space
  build_dependencies
  download_stock_fw
  extract_stock_fw
  build_rom
  echo ">>> Build completed successfully for target: $TARGET"
}

main
