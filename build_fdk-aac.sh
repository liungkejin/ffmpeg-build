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

    local cfg_flags=""
    if [ "$LIBTYPE" = "shared" ]; then
        # cfg_flags="$cfg_flags --enable-shared=yes --enable-static=no --enable-aix-soname=both"
        log_error "Shared library is not supported on $PLATFORM"
        exit 1
    else
        cfg_flags="$cfg_flags --enable-static=yes --enable-shared=no"
    fi

    if [ -f "Makefile" ]; then
        make distclean 2>/dev/null || true
    fi
    rm -rf .libs
    rm -rf autom4te.cache

    if [ ! -f "autogen.sh" ]; then
        log_error "autogen.sh not found. This script must be run from the fdk-aac source directory."
        exit 1
    fi

    ./autogen.sh

    cfg_flags="$cfg_flags
        --disable-dependency-tracking
        --with-pic=yes
        --prefix=$INSTALL_DIR"

    local inherited_cflags="${CFLAGS:-}"
    local inherited_cxxflags="${CXXFLAGS:-$inherited_cflags}"
    local inherited_ldflags="${LDFLAGS:-}"

    export CFLAGS="-O3${inherited_cflags:+ $inherited_cflags}"
    export CXXFLAGS="-O3${inherited_cxxflags:+ $inherited_cxxflags}"
    export LDFLAGS="$inherited_ldflags"

    case "$PLATFORM" in
        android)
            cfg_flags="$cfg_flags --host=$TOOLCHAIN_ARCH --with-sysroot=$SYSROOT"
            CFLAGS="$CFLAGS --sysroot=$SYSROOT"
            CXXFLAGS="$CXXFLAGS --sysroot=$SYSROOT"
            ;;
        harmonyos)
            cfg_flags="$cfg_flags --host=$TOOLCHAIN_ARCH --with-sysroot=$SYSROOT"
            CFLAGS="$CFLAGS --sysroot=$SYSROOT"
            CXXFLAGS="$CXXFLAGS --sysroot=$SYSROOT"
            ;;
        ios)
            cfg_flags="$cfg_flags --host=$HOST"
            CFLAGS="$CFLAGS -fembed-bitcode"
            CXXFLAGS="$CXXFLAGS -fembed-bitcode"
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

    log_info "Configuring fdk-aac with CFLAGS: $CFLAGS"
    log_info "Configuring fdk-aac with flags: $cfg_flags"

    mkdir -p "$INSTALL_DIR"
    ./configure $cfg_flags

    make -j4 && make install

    cd $CUR_DIR
}

build_fdk_aac
