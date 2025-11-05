# 🔧 Xcode 打开项目指南

## ✅ 正确的打开方式

### 重要提示
**不要直接打开 `Runner.xcodeproj`！**  
**必须打开 `Runner.xcworkspace`！**

这是因为项目使用了 CocoaPods 管理依赖，必须使用 `.xcworkspace` 文件。

## 📍 项目路径

```
/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app
```

## 🚀 快速打开方法

### 方法一：使用命令行（推荐）

```bash
# 进入项目目录
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"

# 安装 CocoaPods 依赖（如果还没安装）
cd ios && pod install && cd ..

# 用 Xcode 打开 workspace
open ios/Runner.xcworkspace
```

### 方法二：使用 Finder

1. 打开 Finder
2. 导航到：`桌面 → 安卓苹果 → family_tree_app → ios`
3. **双击 `Runner.xcworkspace`**（不是 .xcodeproj！）
4. Xcode 会自动打开

### 方法三：在终端中直接打开

```bash
open "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios/Runner.xcworkspace"
```

## ⚠️ 常见问题

### Q1: 提示 "No such module 'xxx'"

**原因：** CocoaPods 依赖未安装

**解决：**
```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios"
pod install
```

### Q2: 提示 "Workspace integrity could not be verified"

**解决：**
```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios"
rm -rf Pods Podfile.lock
pod install
```

### Q3: 找不到签名证书

**解决：**
1. 在 Xcode 中：选择项目 **Runner**（左侧导航）
2. 选择 **Signing & Capabilities**
3. 勾选 **Automatically manage signing**
4. 选择你的 **Team**（Apple ID）

### Q4: 打开后显示红色错误

**检查：**
1. 确保已运行 `flutter pub get`
2. 确保已运行 `pod install`
3. 清理构建：**Product → Clean Build Folder**（Shift + Cmd + K）

## 📝 完整设置流程

```bash
# 1. 进入项目目录
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"

# 2. 获取 Flutter 依赖
flutter pub get

# 3. 安装 iOS 依赖（CocoaPods）
cd ios
pod install
cd ..

# 4. 打开 Xcode
open ios/Runner.xcworkspace
```

## ✅ 验证是否打开成功

打开 Xcode 后，你应该看到：
- ✅ 左侧项目导航栏有 **Runner** 项目
- ✅ 有 **Pods** 项目（CocoaPods 依赖）
- ✅ 可以正常构建和运行

## 🎯 快速命令（一键执行）

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app" && \
flutter pub get && \
cd ios && pod install && cd .. && \
open ios/Runner.xcworkspace
```

---

**现在应该可以正常打开 Xcode 了！** 🎉

