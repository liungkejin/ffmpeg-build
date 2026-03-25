#!/usr/bin/env bash

setup_android_toolchain() {
    local arch=$1

    if [ -z "$ANDROID_SDK_PATH" ]; then
        log_error "ANDROID_SDK_PATH is not set"
        return 1
    fi

    local ndk_version="${NDK_VERSION:-27.3.13750724}"
    local api_version="${API_VERSION:-24}"
    export ANDROID_NDK="$ANDROID_SDK_PATH/ndk/$ndk_version"

    if [ ! -d "$ANDROID_NDK" ]; then
        log_error "Android NDK not found at $ANDROID_NDK"
        return 1
    fi

    local platform="$(ls "$ANDROID_NDK/toolchains/llvm/prebuilt" 2>/dev/null | head -n 1)"
    if [ -z "$platform" ]; then
        log_error "Android NDK platform not found"
        return 1
    fi
    export ANDROID_NDK_PLATFORM="$platform"

    local toolchain_dir="$ANDROID_NDK/toolchains/llvm/prebuilt/$platform"
    export SYSROOT="$toolchain_dir/sysroot"

    case "$arch" in
        armeabi-v7a)
            export ARCH="arm"
            export HOST="arm-linux"
            export LIB_ARCH="arm-linux-androideabi"
            export TOOLCHAIN_ARCH="armv7a-linux-androideabi"
            export DISABLE_ASM="--disable-asm"
            ;;
        arm64-v8a)
            export ARCH="arm64"
            export HOST="aarch64-linux"
            export LIB_ARCH="aarch64-linux-android"
            export TOOLCHAIN_ARCH="$LIB_ARCH"
            export DISABLE_ASM=""
            ;;
        x86)
            export ARCH="x86"
            export HOST="i686-linux"
            export LIB_ARCH="i686-linux-android"
            export TOOLCHAIN_ARCH="$LIB_ARCH"
            export DISABLE_ASM="--disable-asm"
            ;;
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-linux"
            export LIB_ARCH="x86_64-linux-android"
            export TOOLCHAIN_ARCH="$LIB_ARCH"
            export DISABLE_ASM=""
            ;;
        *)
            log_error "Unknown Android architecture: $arch"
            return 1
            ;;
    esac

    if [ -d "$toolchain_dir/$LIB_ARCH/bin" ]; then
        export PATH="$toolchain_dir/$LIB_ARCH/bin:$PATH"
    else
        export PATH="$toolchain_dir/bin:$PATH"
    fi

    local toolchain="$toolchain_dir/bin"

    export NM="$toolchain_dir/$LIB_ARCH/bin/nm"
    [ -f "$NM" ] || export NM="$toolchain_dir/bin/llvm-nm"
    export AR="$toolchain_dir/$LIB_ARCH/bin/ar"
    [ -f "$AR" ] || export AR="$toolchain_dir/bin/llvm-ar"
    export AS="$toolchain_dir/$LIB_ARCH/bin/as"
    [ -f "$AS" ] || export AS="$toolchain_dir/bin/llvm-as"
    export LD="$toolchain_dir/$LIB_ARCH/bin/ld"
    [ -f "$LD" ] || export LD="$toolchain_dir/bin/llvm-ld"
    export RANLIB="$toolchain_dir/$LIB_ARCH/bin/ranlib"
    [ -f "$RANLIB" ] || export RANLIB="$toolchain_dir/bin/llvm-ranlib"
    export STRIP="$toolchain_dir/$LIB_ARCH/bin/strip"
    [ -f "$STRIP" ] || export STRIP="$toolchain_dir/bin/llvm-strip"
    export OBJCOPY="$toolchain_dir/$LIB_ARCH/bin/objcopy"
    [ -f "$OBJCOPY" ] || export OBJCOPY="$toolchain_dir/bin/llvm-objcopy"
    export OBJDUMP="$toolchain_dir/$LIB_ARCH/bin/objdump"
    [ -f "$OBJDUMP" ] || export OBJDUMP="$toolchain_dir/bin/llvm-objdump"
    export READELF="$toolchain_dir/$LIB_ARCH/bin/readelf"
    [ -f "$READELF" ] || export READELF="$toolchain_dir/bin/llvm-readelf"

    export CC="$toolchain/$TOOLCHAIN_ARCH$api_version-clang"
    export CXX="$toolchain/$TOOLCHAIN_ARCH$api_version-clang++"
    export CROSS_PREFIX="llvm-"

    export TARGET_OS="android"
    export API_LEVEL="$api_version"

    return 0
}
