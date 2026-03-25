#!/usr/bin/env bash

set -e

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

setup_output_dir() {
    local project=$1
    local arch=$2
    local output_dir="$CUR_DIR/outputs/$project/$arch"
    mkdir -p "$output_dir"
    echo "$output_dir"
}

get_platform_config() {
    local platform=$1
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$script_dir/../platforms/${platform}.sh"
}

check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Command '$cmd' not found. Please install it."
        return 1
    fi
    return 0
}

check_required_env() {
    local env_var=$1
    if [ -z "${!env_var}" ]; then
        log_error "Environment variable '$env_var' is not set."
        return 1
    fi
    return 0
}

parse_arch_list() {
    local arch_input=$1
    if [ "$arch_input" = "all" ]; then
        return 0
    fi
    IFS=',' read -ra ARCHS <<< "$arch_input"
}

get_host_for_arch() {
    local platform=$1
    local arch=$2

    case "$platform" in
        android)
            case "$arch" in
                armeabi-v7a) echo "arm-linux-androideabi" ;;
                arm64-v8a) echo "aarch64-linux-android" ;;
                x86) echo "i686-linux-android" ;;
                x86_64) echo "x86_64-linux-android" ;;
            esac
            ;;
        harmonyos)
            case "$arch" in
                arm64-v8a) echo "aarch64-linux-ohos" ;;
                x86_64) echo "x86_64-linux-ohos" ;;
            esac
            ;;
        ios)
            case "$arch" in
                arm64) echo "arm64-ios" ;;
                x86_64) echo "x86_64-ios" ;;
                universal) echo "universal-ios" ;;
            esac
            ;;
        macos)
            case "$arch" in
                x86_64) echo "x86_64-apple-darwin" ;;
                arm64) echo "arm64-apple-darwin" ;;
                universal) echo "universal-apple-darwin" ;;
            esac
            ;;
        linux)
            case "$arch" in
                x86_64) echo "x86_64-linux-gnu" ;;
                arm64|aarch64) echo "aarch64-linux-gnu" ;;
                armhf|armv7) echo "arm-linux-gnueabihf" ;;
                i386|i686) echo "i686-linux-gnu" ;;
            esac
            ;;
        windows)
            case "$arch" in
                x86_64) echo "x86_64-w64-mingw32" ;;
                x86|i686) echo "i686-w64-mingw32" ;;
                arm64) echo "aarch64-w64-mingw32" ;;
            esac
            ;;
    esac
}

get_cross_prefix() {
    local platform=$1
    local arch=$2

    case "$platform" in
        android)
            case "$arch" in
                armeabi-v7a) echo "armv7a-linux-androideabi" ;;
                arm64-v8a) echo "aarch64-linux-android" ;;
                x86) echo "i686-linux-android" ;;
                x86_64) echo "x86_64-linux-android" ;;
            esac
            ;;
        harmonyos)
            case "$arch" in
                arm64-v8a) echo "aarch64-linux-ohos" ;;
                x86_64) echo "x86_64-linux-ohos" ;;
            esac
            ;;
        linux)
            case "$arch" in
                x86_64) echo "" ;;
                arm64|aarch64) echo "aarch64-linux-gnu-" ;;
                armhf|armv7) echo "arm-linux-gnueabihf-" ;;
                i386|i686) echo "" ;;
            esac
            ;;
        windows)
            case "$arch" in
                x86_64) echo "x86_64-w64-mingw32-" ;;
                x86|i686) echo "i686-w64-mingw32-" ;;
                arm64) echo "aarch64-w64-mingw32-" ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

get_ffmpeg_arch() {
    local arch=$1

    case "$arch" in
        armeabi-v7a) echo "arm" ;;
        arm64-v8a) echo "aarch64" ;;
        x86) echo "x86" ;;
        x86_64) echo "x86_64" ;;
        arm64) echo "aarch64" ;;
        armhf|armv7) echo "arm" ;;
        i386|i686) echo "i686" ;;
        universal)
            echo "arm64 x86_64"
            ;;
        *) echo "$arch" ;;
    esac
}

get_target_os() {
    local platform=$1

    case "$platform" in
        android) echo "android" ;;
        harmonyos) echo "linux" ;;
        ios) echo "ios" ;;
        macos) echo "darwin" ;;
        linux) echo "linux" ;;
        windows) echo "win32" ;;
    esac
}

get_toolchain_path() {
    local platform=$1

    case "$platform" in
        android) echo "$ANDROID_NDK/toolchains/llvm/prebuilt/$ANDROID_NDK_PLATFORM" ;;
        harmonyos) echo "$OHOS_NDK/toolchains/llvm/prebuilt/$OHOS_NDK_PLATFORM" ;;
        *) echo "" ;;
    esac
}

setup_specific_toolchain() {
    local platform=$1
    local arch=$2

    case "$platform" in
        android|harmonyos)
            local toolchain_path=$(get_toolchain_path "$platform")
            if [ -d "$toolchain_path/bin" ]; then
                export PATH="$toolchain_path/bin:$PATH"
            fi
            ;;
        ios|macos)
            if check_command xcrun; then
                local sdk_path=$(xcrun --sdk ${platform} --show-sdk-path 2>/dev/null || echo "")
                if [ -n "$sdk_path" ]; then
                    export SYSROOT="$sdk_path"
                fi
            fi
            ;;
    esac
}

clean_project() {
    local project_dir=$1
    if [ -d "$project_dir" ]; then
        log_info "Cleaning $project_dir..."
        cd "$project_dir"
        if [ -f "Makefile" ] || [ -f "config.h" ]; then
            make clean &> /dev/null || true
        fi
        rm -rf config.* config.h autom4te.cache
        cd "$CUR_DIR"
    fi
}

check_platform_support() {
    local platform=$1
    case "$platform" in
        android|harmonyos|ios|macos|linux|windows) return 0 ;;
        *) return 1 ;;
    esac
}

get_default_arch() {
    local platform=$1
    case "$platform" in
        android) echo "arm64-v8a" ;;
        harmonyos) echo "arm64-v8a" ;;
        ios) echo "arm64" ;;
        macos) echo "arm64" ;;
        linux) echo "x86_64" ;;
        windows) echo "x86_64" ;;
    esac
}

get_supported_archs() {
    local platform=$1
    case "$platform" in
        android) echo "armeabi-v7a arm64-v8a x86 x86_64" ;;
        harmonyos) echo "arm64-v8a x86_64" ;;
        ios) echo "arm64 x86_64 universal" ;;
        macos) echo "x86_64 arm64 universal" ;;
        linux) echo "x86_64 arm64 armhf i386" ;;
        windows) echo "x86_64 x86 arm64" ;;
    esac
}

show_help() {
    cat << EOF
Usage: ./build.sh [OPTIONS]

Options:
  --platform=<platform>      Target platform: android|harmonyos|ios|macos|linux|windows (required)
  --arch=<arch>             Target architecture (default: platform default)
  --libtype=<type>          Library type: static|shared|both (default: static)
  --ffmpeg-version=<ver>    FFmpeg version (default: 8.1)
  --projects=<projs>         Projects to build: all|x264|fdk-aac|ffmpeg (default: all)
  --clean                    Clean before building
  --help                     Show this help message

Examples:
  ./build.sh --platform=android --arch=arm64-v8a --libtype=static
  ./build.sh --platform=ios --arch=arm64 --libtype=shared
  ./build.sh --platform=linux --arch=x86_64 --ffmpeg-version=7.0
  ./build.sh --platform=windows --arch=x86_64 --libtype=both

Supported Platforms: android, harmonyos, ios, macos, linux, windows
Supported Architectures per platform:
  android:    armeabi-v7a, arm64-v8a, x86, x86_64
  harmonyos:  arm64-v8a, x86_64
  ios:        arm64, x86_64, universal
  macos:      x86_64, arm64, universal
  linux:      x86_64, arm64, armhf, i386
  windows:    x86_64, x86, arm64
EOF
}
