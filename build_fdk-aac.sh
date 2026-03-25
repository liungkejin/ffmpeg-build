#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

PLATFORM=$1
ARCH=$2
LIBTYPE=${3:-static}

if [ -z "$PLATFORM" ] || [ -z "$ARCH" ]; then
    log_error "Usage: build_fdk-aac.sh <platform> <arch> [libtype]"
    exit 1
fi

setup_toolchain_for_build() {
    case "$PLATFORM" in
        android)
            source "$SCRIPT_DIR/platforms/android.sh"
            setup_android_toolchain "$ARCH"
            ;;
        harmonyos)
            source "$SCRIPT_DIR/platforms/harmonyos.sh"
            setup_harmonyos_toolchain "$ARCH"
            ;;
        ios)
            source "$SCRIPT_DIR/platforms/ios.sh"
            setup_ios_toolchain "$ARCH"
            ;;
        macos)
            source "$SCRIPT_DIR/platforms/macos.sh"
            setup_macos_toolchain "$ARCH"
            ;;
        linux)
            source "$SCRIPT_DIR/platforms/linux.sh"
            setup_linux_toolchain "$ARCH"
            ;;
        windows)
            source "$SCRIPT_DIR/platforms/windows.sh"
            setup_windows_toolchain "$ARCH"
            ;;
        *)
            log_error "Unsupported platform: $PLATFORM"
            exit 1
            ;;
    esac
}

build_fdk_aac() {
    setup_toolchain_for_build

    if [ -f "Makefile" ]; then
        make clean 2>/dev/null || true
    fi

    if [ ! -f "autogen.sh" ]; then
        log_error "autogen.sh not found. This script must be run from the fdk-aac source directory."
        exit 1
    fi

    ./autogen.sh

    local cfg_flags=""
    if [ "$LIBTYPE" = "shared" ]; then
        cfg_flags="$cfg_flags --enable-shared --disable-static"
    else
        cfg_flags="$cfg_flags --enable-static --disable-shared"
    fi

    cfg_flags="$cfg_flags
        --disable-dependency-tracking
        --with-pic=yes
        --prefix=$INSTALL_DIR
        --disable-asm"


    export CFLAGS="-O3 -fPIC --sysroot=${SYSROOT}"
    export CXXFLAGS="-O3 -fPIC --sysroot=${SYSROOT}"

    case "$PLATFORM" in
        android)
            cfg_flags="$cfg_flags --host=$TOOLCHAIN_ARCH --with-sysroot=$SYSROOT"
            extra_cflags="$extra_cflags --sysroot=$SYSROOT"
            ;;
        harmonyos)
            cfg_flags="$cfg_flags --host=$TOOLCHAIN_ARCH --with-sysroot=$SYSROOT"
            extra_cflags="$extra_cflags --sysroot=$SYSROOT"
            ;;
        ios)
            cfg_flags="$cfg_flags --host=$HOST"
            extra_cflags="$extra_cflags -fembed-bitcode"
            ;;
        macos)
            cfg_flags="$cfg_flags --host=$HOST"
            ;;
        linux)
            cfg_flags="$cfg_flags --host=$HOST"
            ;;
        windows)
            cfg_flags="$cfg_flags --host=$HOST"
            ;;
    esac

    log_info "Configuring fdk-aac with flags: $cfg_flags"

    ./configure $cfg_flags

    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    make install

    cd $CUR_DIR
}

build_fdk_aac
