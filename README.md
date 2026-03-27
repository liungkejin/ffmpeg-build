# ffmpeg-build

一个用于构建 FFmpeg、x264、fdk-aac 的跨平台 Shell 脚本集合，目标是统一 Android、HarmonyOS、iOS、macOS、Linux、Windows 的源码下载、工具链设置和产物输出目录。

当前仓库以 `build.sh` 作为统一入口，源码统一下载到 `source/`，构建产物输出到 `outputs/`。

## 功能概览

- 支持平台：Android、HarmonyOS、iOS、macOS、Linux、Windows
- 支持组件：x264、fdk-aac、FFmpeg
- 支持下载源码并自动解压 / clone
- 支持按平台、架构、组件单独编译
- 支持静态库构建
- 部分平台支持动态库构建

## 源码来源

- FFmpeg：`https://ffmpeg.org/releases/ffmpeg-<version>.tar.xz`
- fdk-aac：`https://github.com/mstorsjo/fdk-aac.git`
- x264：`https://code.videolan.org/videolan/x264.git`

默认 FFmpeg 版本为 `8.1`，可通过参数覆盖。

## 目录结构

```text
ffmpeg-build/
├── build.sh
├── build_x264.sh
├── build_fdk-aac.sh
├── build_ffmpeg.sh
├── platforms/
│   ├── android.sh
│   ├── ohos.sh
│   ├── ios.sh
│   ├── linux.sh
│   ├── macos.sh
│   └── windows.sh
├── scripts/
│   ├── common.sh
│   └── download.sh
├── source/
│   ├── ffmpeg/
│   ├── fdk-aac/
│   └── x264/
└── outputs/
    └── <project>/<platform>/<arch>/
```

## 依赖要求

### 通用依赖

- Bash
- `git`
- `tar`
- `make`
- `curl` 或 `wget`
- `pkg-config`

### fdk-aac 额外依赖

当前 `fdk-aac` 静态库走 Autotools 构建链路，建议本机具备：

- `autoconf`
- `automake`
- `libtool`

在 macOS 上通常需要：

```bash
brew install autoconf automake libtool pkg-config
```

## 平台工具链要求

### Android

需要设置：

```bash
export ANDROID_SDK_PATH=/path/to/Android/sdk
```

可选变量：

```bash
export NDK_VERSION=27.3.13750724
export API_VERSION=24
```

### HarmonyOS

支持以下任一变量：

```bash
export OHOS_NDK=/path/to/openharmony/native
```

或

```bash
export HARMONY_NDK=/path/to/openharmony/native
```

如果不设置，脚本会尝试使用默认路径：

```text
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native
```

### iOS / macOS

需要：

- Xcode
- Command Line Tools
- `xcrun` 可用

### Linux

默认使用系统 GCC / Clang。交叉编译时需要提前安装对应 toolchain。

### Windows

默认按 MinGW-w64 交叉编译方式组织，需要本机已有对应工具链。

## 当前支持情况

下表描述的是当前仓库脚本的实际能力，而不是目标能力。

| 项目 | static | shared | 备注 |
|---|---|---|---|
| x264 | 支持 | 支持 | 已验证 android/ohos/ios/macos |
| fdk-aac | 支持 | 当前脚本不支持 | `build_fdk-aac.sh` 已显式禁止 shared |
| FFmpeg | 支持 | 支持 | 已验证 android/ohos/ios/macos |

### 已实际验证通过

- macOS arm64
  - x264 static/shared
  - fdk-aac static
  - FFmpeg static/shared
- iOS arm64
  - x264 static/shared
  - fdk-aac static
  - FFmpeg static/shared
- Android arm64-v8a/armeabi-v7a/x86/x86_64
  - x264 static/shared
  - fdk-aac static
  - FFmpeg static/shared
- HarmonyOS arm64-v8a
  - x264 static/shared
  - fdk-aac static
  - FFmpeg static/shared

### 当前已知限制

- `fdk-aac` 动态库当前不能通过 `configure && make && make install` 稳定产出  
  根因是上游 Autotools / libtool 在当前 Android 场景下没有真正生成 `.so`，只生成 `.la/.lai` 元数据文件。
- `iOS/macOS universal` 当前不是完整 fat binary 流程，若需要通用二进制，建议后续补充 `lipo` 合并。

## 命令行参数

```bash
./build.sh [OPTIONS]
```

参数说明：

- `--platform=<platform>`：目标平台，必填
- `--arch=<arch>`：目标架构，不填则使用平台默认架构
- `--libtype=<type>`：库类型，当前建议使用 `static` 或 `shared`
- `--ffmpeg-version=<ver>`：FFmpeg 版本，默认 `8.1`
- `--projects=<projs>`：构建项目，支持 `all`、`x264`、`fdk-aac`、`ffmpeg`
- `--clean`：构建前清理
- `--help`：显示帮助

## 支持的平台和架构

### Android

- `armeabi-v7a`
- `arm64-v8a`
- `x86`
- `x86_64`

### HarmonyOS

- `arm64-v8a`
- `x86_64`

### iOS

- `arm64`
- `arm64-v8a`
- `aarch64`
- `x86_64`
- `universal`

### macOS

- `x86_64`
- `arm64`
- `arm64-v8a`
- `aarch64`
- `universal`

### Linux

- `x86_64`
- `arm64`
- `armhf`
- `i386`

### Windows

- `x86_64`
- `x86`
- `arm64`

## 常用示例

### Android

编译 Android arm64-v8a 静态库：

```bash
# 同时编译 x264、fdk-aac、FFmpeg 静态库
./build.sh --platform=android --arch=arm64-v8a --libtype=static
```

只编译 FFmpeg：

```bash
./build.sh --platform=android --arch=arm64-v8a --libtype=static --projects=ffmpeg
```

指定 FFmpeg 版本：

```bash
./build.sh --platform=android --arch=arm64-v8a --libtype=static --ffmpeg-version=7.1
```

### HarmonyOS

```bash
./build.sh --platform=ohos --arch=arm64-v8a --libtype=static
```

### iOS

编译 iOS arm64 FFmpeg 静态库：

```bash
./build.sh --platform=ios --arch=arm64-v8a --libtype=static --projects=ffmpeg
```

编译 iOS arm64 FFmpeg 动态库：

```bash
./build.sh --platform=ios --arch=arm64-v8a --libtype=shared --projects=ffmpeg
```

### macOS

编译 macOS arm64 静态库：

```bash
./build.sh --platform=macos --arch=arm64-v8a --libtype=static
```

分别编译单个组件：

```bash
./build.sh --platform=macos --arch=arm64-v8a --libtype=static --projects=x264
./build.sh --platform=macos --arch=arm64-v8a --libtype=static --projects=fdk-aac
./build.sh --platform=macos --arch=arm64-v8a --libtype=static --projects=ffmpeg
```

### Linux

```bash
./build.sh --platform=linux --arch=x86_64 --libtype=static
```

### Windows

```bash
./build.sh --platform=windows --arch=x86_64 --libtype=static
```

## 输出目录

构建成功后，产物输出到：

```text
outputs/<project>/<platform>/<arch>/
```

例如：

```text
outputs/x264/macos/arm64-v8a
outputs/fdk-aac/macos/arm64-v8a
outputs/ffmpeg/ios/arm64-v8a
```

通常包含：

- `include/`
- `lib/`
- `pkgconfig/`

## 源码目录

源码统一保存在：

```text
source/ffmpeg
source/fdk-aac
source/x264
```

下载缓存保存在：

```text
.downloads/
```
