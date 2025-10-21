#!/bin/sh
set -e  # 遇到错误立即停止
echo "=== CI PRE-XCODEBUILD START ==="

# 1️⃣ 打印环境
flutter --version || echo "Flutter not installed yet"

# 2️⃣ 安装 Flutter（Xcode Cloud 提供缓存，如果有 pubspec.lock 会自动使用）
echo "Running flutter pub get..."
flutter pub get

# 3️⃣ 确保 iOS 文件已生成
echo "Running flutter precache and build ios..."
flutter precache --ios
flutter build ios --release --no-codesign

# 4️⃣ 安装 CocoaPods
cd ios
echo "Running pod install..."
pod install

echo "=== CI PRE-XCODEBUILD END ==="