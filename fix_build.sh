#!/bin/bash
echo "🔧 正在修复构建错误..."

cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"

echo "1️⃣ 清理 Flutter 缓存..."
flutter clean

echo "2️⃣ 清理 iOS 依赖..."
cd ios
rm -rf Pods Podfile.lock .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

echo "3️⃣ 重新获取依赖..."
cd ..
flutter pub get

echo "4️⃣ 重新安装 CocoaPods..."
cd ios
pod deintegrate
pod install
cd ..

echo "5️⃣ 清理 Xcode 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "✅ 修复完成！"
echo "请重新打开 Xcode 项目："
echo "open ios/Runner.xcworkspace"
