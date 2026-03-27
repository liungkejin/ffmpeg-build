#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

export CUR_DIR="$SCRIPT_DIR"
export OUT_DIR="$CUR_DIR/ffmpeg/build"
export SOURCE_DIR="$CUR_DIR/source"

export ALL_PROJECTS=("x264" "fdk-aac" "ffmpeg")

PLATFORM=""
ARCHS=""
LIBTYPE="static"
FFMPEG_VERSION="8.1"
PROJECTS="all"
CLEAN_BUILD=false

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --platform=*)
                PLATFORM="${1#*=}"
                [[ "$PLATFORM" == "harmonyos" ]] && PLATFORM="ohos"
                shift
                ;;
            --arch=*)
                ARCHS="${1#*=}"
                shift
                ;;
            --libtype=*)
                LIBTYPE="${1#*=}"
                shift
                ;;
            --ffmpeg-version=*)
                FFMPEG_VERSION="${1#*=}"
                shift
                ;;
            --projects=*)
                PROJECTS="${1#*=}"
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [ -z "$PLATFORM" ]; then
        log_error "Platform is required. Use --platform=<platform>"
        show_help
        exit 1
    fi

    if ! check_platform_support "$PLATFORM"; then
        log_error "Unsupported platform: $PLATFORM"
        show_help
        exit 1
    fi

    if [ -z "$ARCHS" ]; then
        ARCHS=$(get_default_arch "$PLATFORM")
    fi

    if [ "$ARCHS" = "all" ]; then
        ARCHS=$(get_supported_archs "$PLATFORM")
    fi
}

setup_toolchain() {
    local platform=$1
    local arch=$2

    local platform_script="$SCRIPT_DIR/platforms/${platform}.sh"
    if [ ! -f "$platform_script" ]; then
        log_error "Platform script not found: $platform_script"
        return 1
    fi

    source "$platform_script"

    case "$platform" in
        android)
            setup_android_toolchain "$arch"
            ;;
        ohos)
            setup_ohos_toolchain "$arch"
            ;;
        ios)
            setup_ios_toolchain "$arch"
            ;;
        macos)
            setup_macos_toolchain "$arch"
            ;;
        linux)
            setup_linux_toolchain "$arch"
            ;;
        windows)
            setup_windows_toolchain "$arch"
            ;;
        *)
            log_error "Unsupported platform: $platform"
            return 1
            ;;
    esac
}

download_sources() {
    source "$SCRIPT_DIR/scripts/download.sh"
    download_all "$FFMPEG_VERSION"
}

build_project_abi() {
    local proj=$1
    local platform=$2
    local arch=$3
    local libtype=$4

    log_info "-----------Building $proj for $platform/$arch (libtype: $libtype)-----------"

    local install_dir="$CUR_DIR/outputs/$platform/$proj/$arch"
    export OUTPUTS_DIR="$CUR_DIR/outputs"
    export INSTALL_DIR="$install_dir"
    export PROJ_DIR="$CUR_DIR/source/$proj"

    if [ "$CLEAN_BUILD" = true ]; then
        clean_project "$PROJ_DIR"
    fi

    mkdir -p "$install_dir"

    local build_script="$SCRIPT_DIR/build_${proj}.sh"
    if [ ! -f "$build_script" ]; then
        log_error "Build script not found: $build_script"
        return 1
    fi

    cd "$PROJ_DIR"
    bash "$build_script" "$platform" "$arch" "$libtype"
    cd "$CUR_DIR"
}

build_project() {
    local proj=$1
    local platform=$2
    shift 2
    local archs="$@"

    for arch in $archs; do
        build_project_abi "$proj" "$platform" "$arch" "$LIBTYPE"
    done
}

build() {
    local platform=$1
    local archs="$2"

    if [ "$PROJECTS" = "all" ]; then
        for proj in "${ALL_PROJECTS[@]}"; do
            build_project "$proj" "$platform" "$archs"
        done
    else
        IFS=',' read -ra PROJ_LIST <<< "$PROJECTS"
        for proj in "${PROJ_LIST[@]}"; do
            build_project "$proj" "$platform" "$archs"
        done
    fi
}

main() {
    parse_arguments "$@"

    log_info "Starting FFmpeg cross-platform build"
    log_info "Platform: $PLATFORM"
    log_info "Architecture: $ARCHS"
    log_info "Library type: $LIBTYPE"
    log_info "FFmpeg version: $FFMPEG_VERSION"
    log_info "Projects: $PROJECTS"

    IFS=' ' read -ra ARCH_LIST <<< "$ARCHS"

    for arch in "${ARCH_LIST[@]}"; do
        setup_toolchain "$PLATFORM" "$arch"
        download_sources

        build "$PLATFORM" "$arch"

        log_success "Build completed for $PLATFORM/$arch"
    done

    log_success "All builds completed successfully!"
}

main "$@"
