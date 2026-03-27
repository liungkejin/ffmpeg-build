#!/usr/bin/env bash

setup_ohos_toolchain() {
    local arch=$1
    local ohos_ndk="${OHOS_NDK:-${HARMONYOS_NDK:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native}}"
    if [ -z "$ohos_ndk" ]; then
        log_error "OHOS_NDK or HARMONYOS_NDK environment variable is not set"
        return 1
    fi

    if [ ! -d "$ohos_ndk" ]; then
        log_error "OHOS NDK not found at $ohos_ndk"
        return 1
    fi

    export OHOS_NDK_ROOT="$ohos_ndk"
    local llvm_dir="$ohos_ndk/llvm"

    if [ ! -d "$llvm_dir" ]; then
        log_error "LLVM directory not found at $llvm_dir"
        return 1
    fi

    export SYSROOT="$ohos_ndk/sysroot"

    case "$arch" in
        arm64-v8a|aarch64)
            export ARCH="aarch64"
            export HOST="aarch64-linux"
            export LIB_ARCH="aarch64-linux-ohos"
            export TOOLCHAIN_ARCH="aarch64-unknown-linux-ohos"
            export DISABLE_ASM=""
            ;;
        x86_64)
            export ARCH="x86_64"
            export HOST="x86_64-linux"
            export LIB_ARCH="x86_64-linux-ohos"
            export TOOLCHAIN_ARCH="x86_64-unknown-linux-ohos"
            export DISABLE_ASM=""
            ;;
        *)
            log_error "Unknown OHOS architecture: $arch"
            return 1
            ;;
    esac

    export CC="$llvm_dir/bin/$TOOLCHAIN_ARCH-clang"
    export CXX="$llvm_dir/bin/$TOOLCHAIN_ARCH-clang++"
    export AR="$llvm_dir/bin/llvm-ar"
    export AS="$llvm_dir/bin/llvm-as"
    export RANLIB="$llvm_dir/bin/llvm-ranlib"
    export LD="$llvm_dir/bin/ld.lld"
    export STRIP="$llvm_dir/bin/llvm-strip"
    export NM="$llvm_dir/bin/llvm-nm"
    export OBJCOPY="$llvm_dir/bin/llvm-objcopy"
    export OBJDUMP="$llvm_dir/bin/llvm-objdump"
    export READELF="$llvm_dir/bin/llvm-readelf"

    export CROSS_PREFIX="$llvm_dir/bin/llvm-"

    export TARGET_OS="linux"
    export HOST_OS="linux"

    export CFLAGS="-D__OHOS__=1 -D__HARMONYOS__=1 --sysroot=$SYSROOT -I$SYSROOT/usr/include -I$SYSROOT/usr/include/$LIB_ARCH -fdata-sections -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -fno-addrsig -Wa,--noexecstack"
    export CXXFLAGS="-D__OHOS__=1 -D__HARMONYOS__=1 --sysroot=$SYSROOT -I$SYSROOT/usr/include -I$SYSROOT/usr/include/$LIB_ARCH -fdata-sections -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -fno-addrsig -Wa,--noexecstack"
    export LDFLAGS="--sysroot=$SYSROOT -lstdc++ -lm -lc"

    export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"

    if [ ! -f "$CC" ]; then
        log_error "Compiler not found at $CC"
        return 1
    fi

    return 0
}
