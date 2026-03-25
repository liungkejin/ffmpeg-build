#!/usr/bin/env bash

setup_ios_toolchain() {
    local arch=$1

    if ! check_command xcrun; then
        log_error "xcrun not found. Please install Xcode Command Line Tools."
        return 1
    fi

    local deployment_target="13.0"
    local sdk_name="iphoneos"
    local min_flag=""

    case "$arch" in
        arm64|arm64-v8a|aarch64)
            arch="arm64"
            min_flag="-miphoneos-version-min=$deployment_target"
            ;;
        x86_64)
            sdk_name="iphonesimulator"
            deployment_target="13.0"
            min_flag="-mios-simulator-version-min=$deployment_target"
            ;;
        universal)
            arch="arm64"
            min_flag="-miphoneos-version-min=$deployment_target"
            ;;
        *)
            log_error "Unknown iOS architecture: $arch"
            return 1
            ;;
    esac

    local sdk_path=$(xcrun --sdk "$sdk_name" --show-sdk-path 2>/dev/null)
    if [ -z "$sdk_path" ]; then
        log_error "iOS SDK not found"
        return 1
    fi

    export SDK_PATH="$sdk_path"
    export SYSROOT="$sdk_path"
    export TARGET_OS="ios"
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
        arm64)
            export ARCH="arm64"
            export HOST="aarch64-apple-darwin"
            ;;
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-apple-darwin"
            ;;
        universal)
            export ARCH="arm64"
            export HOST="aarch64-apple-darwin"
            ;;
    esac

    export CROSS_PREFIX=""
    export DISABLE_ASM=""
    export CFLAGS="-arch $ARCH -isysroot $SYSROOT $min_flag"
    export CXXFLAGS="-arch $ARCH -isysroot $SYSROOT $min_flag"
    export LDFLAGS="-arch $ARCH -isysroot $SYSROOT $min_flag"

    return 0
}
