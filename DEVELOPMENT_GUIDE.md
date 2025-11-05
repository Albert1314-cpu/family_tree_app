# 🚀 二次开发指南

## ✅ 当前仓库包含的内容

从 GitHub 拉取代码后，你可以获得：

### 核心文件
- ✅ **源代码** (`lib/` 目录) - 完整的应用代码
- ✅ **项目配置** (`pubspec.yaml`) - Flutter 依赖和配置
- ✅ **Android 配置** (`android/` 目录) - Android 平台配置
- ✅ **iOS 配置** (`ios/` 目录) - iOS 平台配置
- ✅ **Firebase 规则** (`firestore.rules`) - 数据库安全规则

### 可以开始二次开发

**是的，别人拉取这些文件后可以开始二次开发！**

## 📋 开发环境设置步骤

### 1. 克隆仓库
```bash
git clone https://github.com/Albert1314-cpu/family_tree_app.git
cd family_tree_app
```

### 2. 安装 Flutter 依赖
```bash
flutter pub get
```

### 3. 配置 Firebase（重要）

由于 Firebase 配置文件可能包含敏感信息，你需要：

#### Android 配置
1. 在 [Firebase Console](https://console.firebase.google.com/) 创建项目
2. 添加 Android 应用，包名：`com.familytree.app`
3. 下载 `google-services.json`
4. 放置到：`android/app/google-services.json`

#### iOS 配置
1. 在 Firebase Console 添加 iOS 应用，Bundle ID：`com.familytree.app`
2. 下载 `GoogleService-Info.plist`
3. 放置到：`ios/Runner/GoogleService-Info.plist`

### 4. 运行项目
```bash
# 查看可用设备
flutter devices

# 运行到设备/模拟器
flutter run
```

## ⚠️ 注意事项

### 需要自行配置的部分

1. **Firebase 项目**
   - 需要创建自己的 Firebase 项目
   - 配置 Authentication、Firestore、Storage
   - 替换配置文件

2. **应用签名**
   - Android: 需要配置签名密钥（用于发布）
   - iOS: 需要在 Xcode 中配置开发者证书

3. **应用标识符**
   - Android: `com.familytree.app`（可在 `android/app/build.gradle.kts` 修改）
   - iOS: `com.familytree.app`（可在 Xcode 中修改）

4. **依赖版本**
   - 项目使用 Flutter 3.x
   - 某些依赖可能需要更新

## 🔧 开发建议

### 代码结构
```
lib/
├── main.dart              # 应用入口
├── models/               # 数据模型
├── providers/            # 状态管理
├── screens/              # 界面页面
└── services/             # 业务服务
```

### 主要功能模块
- 家族树创建和管理
- 成员信息管理
- 云端同步（Firebase）
- 数据可视化
- 分享功能

## 📝 修改建议

如果你想修改应用：

1. **修改应用名称**
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/Info.plist`

2. **修改包名/Bundle ID**
   - 需要同时修改代码中的引用
   - 更新 Firebase 配置

3. **添加新功能**
   - 在 `lib/screens/` 添加新页面
   - 在 `lib/services/` 添加业务逻辑
   - 在 `lib/models/` 添加数据模型

## 🚨 安全提示

当前仓库可能包含：
- ⚠️ Firebase 配置文件（如果已提交）
- ⚠️ 这些文件可能包含项目特定的配置

**建议**：
- 如果这是公开仓库，考虑移除敏感配置文件
- 使用 `.gitignore` 排除这些文件
- 提供配置模板文件（如 `google-services.json.example`）

## 📚 学习资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Firebase Flutter 文档](https://firebase.flutter.dev/)
- [Dart 语言指南](https://dart.dev/guides)

## ❓ 常见问题

**Q: 可以直接运行吗？**
A: 需要先配置 Firebase 项目，否则无法使用云端功能。

**Q: 可以使用自己的 Firebase 项目吗？**
A: 可以，需要替换配置文件并更新代码中的 Firebase 初始化。

**Q: 如何修改应用图标？**
A: 
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

---

**祝开发顺利！** 🎉

