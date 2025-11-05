#!/bin/bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
echo "🔄 正在刷新配置..."
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
echo "✅ 配置已刷新，请重新打开 Xcode 项目"
open ios/Runner.xcworkspace
