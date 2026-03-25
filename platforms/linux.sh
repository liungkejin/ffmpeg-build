#!/usr/bin/env bash

setup_linux_toolchain() {
    local arch=$1

    case "$arch" in
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-linux-gnu"
            export CC="${CC:-gcc}"
            export CXX="${CXX:-g++}"
            export CROSS_PREFIX=""
            export DISABLE_ASM=""
            ;;
        arm64|aarch64)
            export ARCH="aarch64"
            export HOST="aarch64-linux-gnu"
            local cross_prefix="${CROSS_PREFIX:-aarch64-linux-gnu-}"
            if ! command -v "${cross_prefix}gcc" &> /dev/null; then
                log_error "Cross-compiler $cross_prefix-gcc not found. Please install gcc-aarch64-linux-gnu"
                return 1
            fi
            export CC="${CC:-$cross_prefix gcc}"
            export CXX="${CXX:-$cross_prefix g++}"
            export AR="${AR:-$cross_prefix ar}"
            export RANLIB="${RANLIB:-$cross_prefix ranlib}"
            export STRIP="${STRIP:-$cross_prefix strip}"
            export NM="${NM:-$cross_prefix nm}"
            export CROSS_PREFIX="$cross_prefix"
            export DISABLE_ASM=""
            ;;
        armhf|armv7)
            export ARCH="arm"
            export HOST="arm-linux-gnueabihf"
            local cross_prefix="${CROSS_PREFIX:-arm-linux-gnueabihf-}"
            if ! command -v "${cross_prefix}gcc" &> /dev/null; then
                log_error "Cross-compiler $cross_prefix-gcc not found. Please install gcc-arm-linux-gnueabihf"
                return 1
            fi
            export CC="${CC:-$cross_prefix gcc}"
            export CXX="${CXX:-$cross_prefix g++}"
            export AR="${AR:-$cross_prefix ar}"
            export RANLIB="${RANLIB:-$cross_prefix ranlib}"
            export STRIP="${STRIP:-$cross_prefix strip}"
            export NM="${NM:-$cross_prefix nm}"
            export CROSS_PREFIX="$cross_prefix"
            export DISABLE_ASM="--disable-asm"
            ;;
        i386|i686)
            export ARCH="i686"
            export HOST="i686-linux-gnu"
            export CC="${CC:-gcc}"
            export CXX="${CXX:-g++}"
            export CROSS_PREFIX=""
            export DISABLE_ASM=""
            ;;
        *)
            log_error "Unknown Linux architecture: $arch"
            return 1
            ;;
    esac

    export TARGET_OS="linux"
    export SYSROOT=""

    return 0
}
