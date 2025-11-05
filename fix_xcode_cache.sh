#!/bin/bash
echo "🧹 正在清理 Xcode 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null
echo "✅ Xcode 缓存已清理"
echo "请重新打开 Xcode 并重试"
