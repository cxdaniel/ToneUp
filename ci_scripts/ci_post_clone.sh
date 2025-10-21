#!/bin/bash
set -e

# 切换到ios目录
cd ios

# 安装CocoaPods依赖
pod install

# 可选：若项目是Flutter，可添加Flutter依赖安装命令
# cd ..
# flutter pub get