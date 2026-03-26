#!/bin/bash

./build.sh --platform=android --arch=arm64-v8a --libtype=static
./build.sh --platform=android --arch=armeabi-v7a --libtype=static

./build.sh --platform=harmonyos --arch=arm64-v8a --libtype=static

./build.sh --platform=ios --arch=arm64-v8a --libtype=static

./build.sh --platform=macos --arch=arm64 --libtype=static
