#!/usr/bin/env bash

SOURCE_DIR="$CUR_DIR/source"
DOWNLOAD_DIR="$CUR_DIR/.downloads"

download_ffmpeg() {
    local version=$1
    local ffmpeg_tarball="$DOWNLOAD_DIR/ffmpeg-${version}.tar.xz"
    local ffmpeg_dir="$SOURCE_DIR/ffmpeg"

    if [ -d "$ffmpeg_dir" ] && [ -f "$ffmpeg_dir/configure" ]; then
        log_info "FFmpeg source already exists at $ffmpeg_dir, skipping download."
        return 0
    fi

    mkdir -p "$DOWNLOAD_DIR"
    mkdir -p "$SOURCE_DIR"

    local ffmpeg_url="https://ffmpeg.org/releases/ffmpeg-${version}.tar.xz"
    log_info "Downloading FFmpeg ${version} from $ffmpeg_url..."

    if command -v curl &> /dev/null; then
        curl -L -o "$ffmpeg_tarball" "$ffmpeg_url" || {
            log_error "Failed to download FFmpeg"
            return 1
        }
    elif command -v wget &> /dev/null; then
        wget -O "$ffmpeg_tarball" "$ffmpeg_url" || {
            log_error "Failed to download FFmpeg"
            return 1
        }
    else
        log_error "Neither curl nor wget found. Please install one of them."
        return 1
    fi

    log_info "Extracting FFmpeg..."
    rm -rf "$ffmpeg_dir"
    tar -xf "$ffmpeg_tarball" -C "$SOURCE_DIR" || {
        log_error "Failed to extract FFmpeg"
        return 1
    }

    local extracted_dir="$SOURCE_DIR/ffmpeg-${version}"
    if [ -d "$extracted_dir" ]; then
        mv "$extracted_dir" "$ffmpeg_dir"
    fi

    rm -f "$ffmpeg_tarball"
    log_success "FFmpeg ${version} downloaded and extracted to $ffmpeg_dir"
    return 0
}

download_fdk_aac() {
    local fdk_aac_dir="$SOURCE_DIR/fdk-aac"

    if [ -d "$fdk_aac_dir" ] && [ -f "$fdk_aac_dir/autogen.sh" ]; then
        log_info "fdk-aac source already exists at $fdk_aac_dir, skipping download."
        return 0
    fi

    mkdir -p "$SOURCE_DIR"

    local fdk_aac_url="https://github.com/mstorsjo/fdk-aac.git"
    log_info "Downloading fdk-aac from $fdk_aac_url..."

    if [ -d "$fdk_aac_dir" ]; then
        rm -rf "$fdk_aac_dir"
    fi

    git clone "$fdk_aac_url" "$fdk_aac_dir" || {
        log_error "Failed to clone fdk-aac"
        return 1
    }

    log_success "fdk-aac cloned to $fdk_aac_dir"
    return 0
}

download_x264() {
    local x264_dir="$SOURCE_DIR/x264"

    if [ -d "$x264_dir" ] && [ -f "$x264_dir/Makefile" ]; then
        log_info "x264 source already exists at $x264_dir, skipping download."
        return 0
    fi

    mkdir -p "$SOURCE_DIR"

    local x264_url="https://code.videolan.org/videolan/x264.git"
    log_info "Downloading x264 from $x264_url..."

    if [ -d "$x264_dir" ]; then
        rm -rf "$x264_dir"
    fi

    git clone "$x264_url" "$x264_dir" || {
        log_error "Failed to clone x264"
        return 1
    }

    log_success "x264 cloned to $x264_dir"
    return 0
}

download_all() {
    local ffmpeg_version=${1:-"8.1"}

    download_ffmpeg "$ffmpeg_version" || return 1
    download_fdk_aac || return 1
    download_x264 || return 1

    return 0
}
