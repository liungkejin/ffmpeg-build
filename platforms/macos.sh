#!/usr/bin/env bash

setup_macos_toolchain() {
    local arch=$1

    if ! check_command xcrun; then
        log_error "xcrun not found. Please install Xcode Command Line Tools."
        return 1
    fi

    local sdk_name="macosx"
    local deployment_target="${MACOSX_DEPLOYMENT_TARGET:-11.0}"

    case "$arch" in
        x86_64|arm64|universal)
            ;;
        arm64-v8a|aarch64)
            arch="arm64"
            ;;
        *)
            log_error "Unknown macOS architecture: $arch"
            return 1
            ;;
    esac

    local sdk_path=$(xcrun --sdk "$sdk_name" --show-sdk-path 2>/dev/null)
    if [ -z "$sdk_path" ]; then
        log_error "macOS SDK not found"
        return 1
    fi

    export SDK_PATH="$sdk_path"
    export SYSROOT="$sdk_path"
    export TARGET_OS="darwin"
    export DEPLOYMENT_TARGET="$deployment_target"

    local toolchain=$(xcrun --sdk "$sdk_name" -find clang 2>/dev/null)
    local toolchain_path=$(dirname "$toolchain")

    export CC="$toolchain"
    export CXX="$toolchain_path/clang++"
    export AR="$toolchain_path/ar"
    export RANLIB="$toolchain_path/ranlib"
    export STRIP="$toolchain_path/strip"
    export NM="$toolchain_path/nm"
    export LDSHARED="$toolchain"

    case "$arch" in
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-apple-darwin"
            ;;
        arm64)
            export ARCH="arm64"
            export HOST="aarch64-apple-darwin"
            ;;
        universal)
            export ARCH="arm64 x86_64"
            export HOST="aarch64-apple-darwin"
            ;;
    esac

    export CROSS_PREFIX=""
    export DISABLE_ASM=""
    if [ "$ARCH" = "arm64 x86_64" ]; then
        export CFLAGS="-arch arm64 -arch x86_64 -isysroot $SYSROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
        export CXXFLAGS="-arch arm64 -arch x86_64 -isysroot $SYSROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
        export LDFLAGS="-arch arm64 -arch x86_64 -isysroot $SYSROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
    else
        export CFLAGS="-arch $ARCH -isysroot $SYSROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
        export CXXFLAGS="-arch $ARCH -isysroot $SYSROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
        export LDFLAGS="-arch $ARCH -isysroot $SYSROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
    fi

    return 0
}
