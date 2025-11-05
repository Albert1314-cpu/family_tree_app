# 🔧 解决 "Command PhaseScriptExecution failed" 错误

## ❌ 错误信息

```
Command PhaseScriptExecution failed with a nonzero exit code
```

## 🔍 问题原因

这是 Xcode 构建脚本执行失败的错误，常见原因：
1. **CocoaPods 依赖问题**
2. **Flutter 脚本路径问题**
3. **权限问题**
4. **缓存损坏**
5. **Xcode 版本兼容性问题**

## ✅ 解决方案

### 方案一：清理并重新安装依赖（最常见）

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"

# 1. 清理 Flutter 构建缓存
flutter clean

# 2. 清理 iOS 依赖
cd ios
rm -rf Pods Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

# 3. 重新获取依赖
cd ..
flutter pub get

# 4. 重新安装 CocoaPods
cd ios
pod deintegrate
pod install
cd ..

# 5. 重新打开项目
open ios/Runner.xcworkspace
```

### 方案二：检查 Flutter 路径

1. **在 Xcode 中**：
   - 选择项目 **Runner**（左侧导航栏）
   - 选择 **Build Phases** 标签
   - 展开 **"Run Script"** 部分
   - 检查脚本路径是否正确

2. **修复脚本路径**（如果需要）：
   ```bash
   # 获取 Flutter 路径
   which flutter
   
   # 在 Xcode Run Script 中，确保路径正确
   # 应该类似：/path/to/flutter/packages/flutter_tools/bin/xcode_backend.sh
   ```

### 方案三：清理 Xcode 构建缓存

```bash
# 清理 Xcode DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 清理 Xcode 缓存
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

# 重新打开 Xcode
```

### 方案四：检查权限

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios"

# 确保脚本有执行权限
chmod +x Pods/Target\ Support\ Files/Pods-Runner/Pods-Runner-frameworks.sh
chmod +x Flutter/ephemeral/flutter_export_environment.sh
```

### 方案五：查看详细错误信息

在 Xcode 中查看详细错误：

1. **点击错误信息**（在问题导航器中）
2. **查看详细日志**：
   - 点击左侧的红色错误图标
   - 查看 "Show in Report Navigator"
   - 展开失败的脚本步骤
   - 查看具体的错误信息

### 方案六：修复 CocoaPods 问题

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios"

# 更新 CocoaPods
sudo gem install cocoapods

# 清理并重新安装
pod deintegrate
pod cache clean --all
pod install --repo-update
```

### 方案七：使用 Flutter 命令构建

如果 Xcode 构建失败，尝试使用 Flutter 命令：

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"

# 清理
flutter clean

# 构建 iOS（这会自动处理依赖）
flutter build ios

# 然后在 Xcode 中打开
open ios/Runner.xcworkspace
```

---

## 🎯 快速修复脚本

我已经创建了一个一键修复脚本：

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
./fix_build.sh
```

---

## 📝 详细错误诊断

### 查看具体失败的脚本

在 Xcode 中：

1. **打开 Report Navigator**（左侧导航栏，最后一个图标，像文档的图标）
2. **选择失败的构建**
3. **展开失败的步骤**
4. **查看具体的脚本输出**

常见错误包括：
- `pod install` 失败
- Flutter 脚本找不到
- 权限被拒绝
- 路径错误

---

## 🔍 常见具体错误

### 错误 1: "pod: command not found"

**解决**：
```bash
sudo gem install cocoapods
```

### 错误 2: "Flutter.framework not found"

**解决**：
```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
flutter clean
flutter pub get
cd ios
pod install
```

### 错误 3: "Permission denied"

**解决**：
```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios"
chmod -R 755 Pods
chmod +x Pods/**/*.sh
```

### 错误 4: "No such file or directory"

**解决**：
- 检查 Flutter 路径是否正确
- 重新运行 `flutter pub get`
- 重新安装 Pods

---

## ✅ 验证修复

修复后，应该可以：
- ✅ 正常构建项目
- ✅ 没有脚本执行错误
- ✅ 可以运行到设备

---

## 💡 如果还是不行

请提供：
1. **Xcode 中的详细错误信息**（在 Report Navigator 中查看）
2. **具体是哪个脚本失败**（pod install、Flutter script 等）
3. **完整的错误日志**

这样我可以给出更精确的解决方案。

---

**按照上述步骤操作，应该可以解决构建错误！** 🔧

