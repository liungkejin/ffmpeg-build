#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

PLATFORM=$1
ARCH=$2
LIBTYPE=${3:-static}

if [ -z "$PLATFORM" ] || [ -z "$ARCH" ]; then
    log_error "Usage: build_x264.sh <platform> <arch> [libtype]"
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

build_x264() {
    setup_toolchain_for_build

    if [ -f "compat/strtod.o" ]; then
        make clean 2>/dev/null || true
        rm -rf compat/strtod.o
    fi

    if [ -f "./config.h" ]; then
        make clean 2>/dev/null || true
        rm -rf config.h config.mak
    fi

    export CFLAGS="-O3 -fPIC"
    export LDFLAGS=""

    local cfg_flags=""

    if [ "$LIBTYPE" = "shared" ]; then
        cfg_flags="$cfg_flags --enable-shared"
    else
        cfg_flags="$cfg_flags --enable-static --enable-pic"
    fi

    cfg_flags="$cfg_flags
        --disable-opencl
        --disable-cli
        --enable-strip
        --disable-interlaced
        --disable-avs
        --disable-swscale
        --disable-lavf
        --disable-ffms
        --disable-gpac
        --prefix=$INSTALL_DIR
        --disable-asm"

    case "$PLATFORM" in
        android)
            cfg_flags="$cfg_flags --host=$HOST --sysroot=$SYSROOT --cross-prefix=$CROSS_PREFIX"
            ;;
        harmonyos)
            cfg_flags="$cfg_flags --host=$HOST --sysroot=$SYSROOT --cross-prefix=$CROSS_PREFIX"
            ;;
        ios)
            cfg_flags="$cfg_flags --host=$HOST"
            ;;
        macos)
            cfg_flags="$cfg_flags --host=$HOST"
            ;;
        linux)
            cfg_flags="$cfg_flags --host=$HOST"
            if [ -n "$CROSS_PREFIX" ]; then
                cfg_flags="$cfg_flags --cross-prefix=$CROSS_PREFIX"
            fi
            ;;
        windows)
            cfg_flags="$cfg_flags --host=$HOST --cross-prefix=$CROSS_PREFIX"
            ;;
    esac

    log_info "Configuring x264 with CFLAGS: $CFLAGS"
    log_info "Configuring x264 with LDFLAGS: $LDFLAGS"

    mkdir -p build/$ARCH
    cd build/$ARCH

    if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "macos" ]; then
        LDFLAGS="-arch $ARCH" CC="$CC" CXX="$CXX" \
            ../../configure $cfg_flags
    else
        ./../../configure $cfg_flags --extra-cflags="$CFLAGS" --extra-ldflags="$LDFLAGS"
    fi

    cp config.* $INSTALL_DIR 2>/dev/null || true
    make -j4
    make install

    cd $CUR_DIR
}

build_x264
