#!/usr/bin/env bash

setup_windows_toolchain() {
    local arch=$1

    local mingw_root="${MINGW_ROOT:-${MSYSTEM:-}}"
    if [ -z "$mingw_root" ]; then
        if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
            mingw_root="x86_64-w64-mingw32"
        elif command -v mingw32-gcc &> /dev/null; then
            mingw_root="mingw32"
        else
            log_error "MinGW-w64 not found. Please install MinGW-w64."
            return 1
        fi
    fi

    case "$arch" in
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-w64-mingw32"
            local prefix="${MINGW_PREFIX:-x86_64-w64-mingw32-}"
            export CC="${CC:-$prefix gcc}"
            export CXX="${CXX:-$prefix g++}"
            export AR="${AR:-$prefix ar}"
            export RANLIB="${RANLIB:-$prefix ranlib}"
            export STRIP="${STRIP:-$prefix strip}"
            export NM="${NM:-$prefix nm}"
            export CROSS_PREFIX="$prefix"
            export DISABLE_ASM=""
            ;;
        x86|i686)
            export ARCH="i686"
            export HOST="i686-w64-mingw32"
            local prefix="${MINGW_PREFIX:-i686-w64-mingw32-}"
            export CC="${CC:-$prefix gcc}"
            export CXX="${CXX:-$prefix g++}"
            export AR="${AR:-$prefix ar}"
            export RANLIB="${RANLIB:-$prefix ranlib}"
            export STRIP="${STRIP:-$prefix strip}"
            export NM="${NM:-$prefix nm}"
            export CROSS_PREFIX="$prefix"
            export DISABLE_ASM=""
            ;;
        arm64)
            export ARCH="arm64"
            export HOST="aarch64-w64-mingw32"
            local prefix="${MINGW_PREFIX:-aarch64-w64-mingw32-}"
            export CC="${CC:-$prefix gcc}"
            export CXX="${CXX:-$prefix g++}"
            export AR="${AR:-$prefix ar}"
            export RANLIB="${RANLIB:-$prefix ranlib}"
            export STRIP="${STRIP:-$prefix strip}"
            export NM="${NM:-$prefix nm}"
            export CROSS_PREFIX="$prefix"
            export DISABLE_ASM=""
            ;;
        *)
            log_error "Unknown Windows architecture: $arch"
            return 1
            ;;
    esac

    export TARGET_OS="win32"
    export SYSROOT=""

    return 0
}
