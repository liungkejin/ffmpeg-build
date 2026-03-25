#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

PLATFORM=$1
ARCH=$2
LIBTYPE=${3:-static}

if [ -z "$PLATFORM" ] || [ -z "$ARCH" ]; then
    log_error "Usage: build_ffmpeg.sh <platform> <arch> [libtype]"
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

build_ffmpeg() {
    setup_toolchain_for_build

    local build_dir="build/$PLATFORM/$ARCH"

    if [ -f "compat/strtod.o" ]; then
        make clean 2>/dev/null || true
        rm -rf compat/strtod.o
    fi

    if [ -f "./config.h" ]; then
        make clean 2>/dev/null || true
        rm -rf config.h config.log config.fate config.mk
    fi

    local ffmpeg_arch=$(get_ffmpeg_arch "$ARCH")
    local target_os=$(get_target_os "$PLATFORM")

    local cfg_flags="--arch=$ffmpeg_arch"

    case "$PLATFORM" in
        android)
            case "$ARCH" in
                armeabi-v7a)
                    cfg_flags="$cfg_flags --cpu=cortex-a8 --enable-neon --enable-thumb"
                    ;;
                arm64-v8a)
                    ;;
                x86)
                    cfg_flags="$cfg_flags --cpu=i686 --disable-x86asm"
                    ;;
                x86_64)
                    cfg_flags="$cfg_flags --disable-x86asm"
                    ;;
            esac
            ;;
        ios|macos)
            cfg_flags="$cfg_flags --enable-inline-asm"
            ;;
        windows)
            cfg_flags="$cfg_flags --disable-x86asm"
            ;;
    esac

    if [ "$LIBTYPE" = "shared" ]; then
        cfg_flags="$cfg_flags --enable-shared --disable-static"
    else
        cfg_flags="$cfg_flags --enable-static --disable-shared"
    fi

    cfg_flags="$cfg_flags
        --disable-all
        --enable-swscale
        --disable-network
        --disable-avdevice
        --enable-gpl
        --disable-swscale-alpha
        --disable-runtime-cpudetect
        --disable-programs
        --disable-ffmpeg
        --disable-ffplay
        --disable-ffprobe
        --disable-debug
        --disable-vulkan
        --enable-small
        --enable-pic
        --enable-avfilter
        --enable-avcodec
        --enable-avformat
        --enable-avutil
        --enable-swresample
        --disable-everything
        --enable-decoder=mp3
        --enable-decoder=aac
        --enable-decoder=aac_latm
        --enable-decoder=h264
        --enable-decoder=hevc
        --enable-decoder=vp9
        --enable-decoder=mp2
        --enable-demuxer=mp3
        --enable-demuxer=mov
        --enable-demuxer=aac
        --enable-demuxer=h264
        --enable-demuxer=hevc
        --enable-demuxer=rawvideo
        --enable-demuxer=flv
        --enable-demuxer=mpegvideo
        --enable-demuxer=avi
        --enable-demuxer=webm
        --enable-demuxer=mkv
        --enable-muxer=mp4
        --enable-muxer=webm
        --enable-muxer=mkv
        --enable-muxer=adts
        --enable-parser=aac
        --enable-parser=mp3
        --enable-parser=h264
        --enable-parser=hevc
        --enable-bsf=aac_adtstoasc
        --enable-bsf=h264_mp4toannexb
        --enable-bsf=hevc_mp4toannexb
        --enable-bsf=mp3_header_compress
        --enable-bsf=mp3_header_decompress
        --enable-protocol=file
        --enable-protocol=rtmp
        --enable-protocol=http
        --enable-filter=abuffer
        --enable-filter=abuffersink
        --enable-filter=volume
        --enable-filter=aformat
        --enable-filter=atrim
        --enable-filter=aresample
        --enable-filter=amix
        --enable-filter=scale
        --enable-filter=overlay
        --prefix=$INSTALL_DIR
        "

    local inherited_cflags="${CFLAGS:-}"
    local inherited_ldflags="${LDFLAGS:-}"
    local extra_cflags="$inherited_cflags"
    local extra_ldflags="$inherited_ldflags"
    local host_cc=""
    local host_cflags=""
    local host_ldflags=""

    local dep_x264="$OUTPUTS_DIR/x264/$PLATFORM/$ARCH"
    local dep_x264_inc="$dep_x264/include"
    local dep_x264_lib="$dep_x264/lib"

    local dep_fdk_aac="$OUTPUTS_DIR/fdk-aac/$PLATFORM/$ARCH"
    local dep_fdk_aac_inc="$dep_fdk_aac/include"
    local dep_fdk_aac_lib="$dep_fdk_aac/lib"

    if [ -f "${dep_x264_lib}/libx264.a" ] || [ -f "${dep_x264_lib}/libx264.${LIB_EXT:-a}" ] 2>/dev/null; then
        cfg_flags="$cfg_flags --enable-libx264 --enable-encoder=libx264"
        export PKG_CONFIG_PATH="$dep_x264_lib/pkgconfig:$PKG_CONFIG_PATH"
        if [ -f "$dep_x264_lib/pkgconfig/x264.pc" ]; then
            sed -i '' -e "s:^prefix=\(.*\):prefix=$dep_x264:g" "$dep_x264_lib/pkgconfig/x264.pc"
        fi
        extra_cflags="$extra_cflags -I${dep_x264_inc}"
        extra_ldflags="$extra_ldflags -L${dep_x264_lib}"
    fi

    if [ -f "${dep_fdk_aac_lib}/libfdk-aac.a" ] || [ -f "${dep_fdk_aac_lib}/libfdk-aac.${LIB_EXT:-a}" ] 2>/dev/null; then
        cfg_flags="$cfg_flags --enable-nonfree --enable-libfdk_aac --enable-encoder=libfdk_aac --enable-muxer=adts"
        export PKG_CONFIG_PATH="$dep_fdk_aac_lib/pkgconfig:$PKG_CONFIG_PATH"
        if [ -f "$dep_fdk_aac_lib/pkgconfig/fdk-aac.pc" ]; then
            sed -i '' -e "s:^prefix=\(.*\):prefix=$dep_fdk_aac:g" "$dep_fdk_aac_lib/pkgconfig/fdk-aac.pc"
        fi
        extra_cflags="$extra_cflags -I${dep_fdk_aac_inc}"
        extra_ldflags="$extra_ldflags -L${dep_fdk_aac_lib}"
    fi

    case "$PLATFORM" in
        android)
            cfg_flags="$cfg_flags --enable-cross-compile --target-os=android --sysroot=$SYSROOT"
            cfg_flags="$cfg_flags --cc=$CC --cxx=$CXX"
            ;;
        harmonyos)
            cfg_flags="$cfg_flags --enable-cross-compile --target-os=linux --sysroot=$SYSROOT"
            cfg_flags="$cfg_flags --cc=$CC --cxx=$CXX"
            ;;
        ios)
            cfg_flags="$cfg_flags --enable-cross-compile --target-os=darwin --sysroot=$SYSROOT"
            cfg_flags="$cfg_flags --cc=$CC --cxx=$CXX"
            ;;
        macos)
            cfg_flags="$cfg_flags --target-os=darwin --cc=$CC --cxx=$CXX"
            host_cc="$CC"
            host_cflags="$extra_cflags"
            host_ldflags="$extra_ldflags"
            ;;
        linux)
            cfg_flags="$cfg_flags --target-os=linux --cc=$CC --cxx=$CXX"
            if [ -n "$CROSS_PREFIX" ]; then
                cfg_flags="$cfg_flags --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
            fi
            ;;
        windows)
            cfg_flags="$cfg_flags --enable-cross-compile --target-os=win32 --cc=$CC --cxx=$CXX"
            ;;
    esac

    log_info "Configuring FFmpeg with flags: $cfg_flags"
    log_info "Configuring FFmpeg with extra CFLAGS: $extra_cflags"
    log_info "Configuring FFmpeg with extra LDFLAGS: $extra_ldflags"
    [ -n "$host_cc" ] && log_info "Configuring FFmpeg with host CC: $host_cc"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    ./../../../configure $cfg_flags \
        ${host_cc:+--host-cc="$host_cc"} \
        ${host_cflags:+--host-cflags="$host_cflags"} \
        ${host_ldflags:+--host-ldflags="$host_ldflags"} \
        --extra-cflags="$extra_cflags" \
        --extra-ldflags="$extra_ldflags"

    cp config.* $INSTALL_DIR 2>/dev/null || true

    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    make install

    cd $CUR_DIR
}

build_ffmpeg
