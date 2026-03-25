#!/usr/bin/env bash

setup_ios_toolchain() {
    local arch=$1

    if ! check_command xcrun; then
        log_error "xcrun not found. Please install Xcode Command Line Tools."
        return 1
    fi

    local deployment_target="13.0"
    local sdk_name="iphoneos"
    local archs_for_build="arm64"

    case "$arch" in
        arm64)
            ;;
        x86_64)
            sdk_name="iphonesimulator"
            deployment_target="13.0"
            ;;
        universal)
            archs_for_build="arm64 x86_64"
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
            export HOST="arm64-ios"
            export AS="arm64-apple-darwin-as"
            ;;
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-ios"
            ;;
        universal)
            export ARCH="arm64 x86_64"
            export HOST="arm64-ios"
            ;;
    esac

    export CROSS_PREFIX=""
    export DISABLE_ASM=""

    return 0
}
