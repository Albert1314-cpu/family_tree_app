# 💳 付费 Apple Developer 账号配置指南

## 📍 在 Xcode 中登录付费账号

### 步骤 1：打开 Xcode Preferences

1. **打开 Xcode**
2. 点击顶部菜单：**Xcode → Settings**（或按 `Cmd + ,`）
3. 选择 **Accounts**（账户）标签

### 步骤 2：添加 Apple ID

1. 点击左下角的 **+** 按钮
2. 选择 **Apple ID**
3. 输入你的付费账号邮箱和密码
4. 点击 **Sign In**（登录）

### 步骤 3：验证登录成功

登录后，你应该看到：
- ✅ 你的 Apple ID 出现在列表中
- ✅ 显示 **Personal Team** 或 **Apple Developer Program**（付费账号）
- ✅ 如果显示 "Apple Developer Program"，说明是付费账号

---

## 🔧 在项目中配置签名

### 步骤 1：打开项目

```bash
open "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios/Runner.xcworkspace"
```

### 步骤 2：配置签名

1. **在 Xcode 左侧导航栏**，点击最顶部的 **Runner** 项目（蓝色图标）
2. **选择 Target**：在中间区域，选择 **Runner**（在 TARGETS 下）
3. **选择 Signing & Capabilities** 标签
4. **配置签名**：
   - ✅ 勾选 **Automatically manage signing**
   - 在 **Team** 下拉菜单中选择你的付费账号
   - 如果显示 "Apple Developer Program"，说明已正确识别付费账号

### 步骤 3：验证 Bundle ID

确保 **Bundle Identifier** 是唯一的，例如：
- `com.yourname.familytreeapp`
- 不能与其他应用重复

---

## ✅ 验证配置

配置完成后，你应该看到：
- ✅ **Team** 显示你的付费账号
- ✅ **Signing Certificate** 显示有效证书
- ✅ **Provisioning Profile** 自动生成
- ✅ 没有红色错误提示

---

## 🚀 使用付费账号的优势

使用付费账号（$99/年）后：
- ✅ 应用有效期 **1 年**（而不是 7 天）
- ✅ 可以安装到**任何设备**（无需设备 UDID）
- ✅ 可以**发布到 App Store**
- ✅ 应用可以**独立运行**，无需连接 Mac
- ✅ 更好的技术支持

---

## 📱 安装到 iPhone

配置完成后，安装应用：

### 方法一：使用 Xcode

1. **连接 iPhone** 到 Mac
2. **选择设备**：在 Xcode 顶部工具栏选择你的 iPhone
3. **点击运行**：点击运行按钮（▶️）或按 `Cmd + R`
4. **首次安装**：在 iPhone 上信任开发者证书
   - 设置 → 通用 → VPN与设备管理 → 信任

### 方法二：使用 Flutter 命令

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
flutter run
```

---

## 🔍 检查账号状态

### 查看账号类型

在 Xcode → Settings → Accounts：
- **Personal Team**：免费账号（7天有效期）
- **Apple Developer Program**：付费账号（1年有效期）

### 查看账号有效期

1. Xcode → Settings → Accounts
2. 选择你的账号
3. 查看右侧显示的信息
4. 或访问：https://developer.apple.com/account

---

## ⚠️ 常见问题

### Q1: 找不到我的付费账号

**解决**：
1. 确认账号已登录：Xcode → Settings → Accounts
2. 如果账号显示 "Personal Team"，可能账号未激活付费计划
3. 检查：https://developer.apple.com/account → 查看是否显示 "Apple Developer Program"

### Q2: 提示 "No signing certificate found"

**解决**：
1. 在 Xcode → Settings → Accounts
2. 选择你的账号
3. 点击 **Download Manual Profiles**
4. 在项目中重新选择 Team

### Q3: 提示 "Device not registered"

**解决**：
- 付费账号通常不需要手动注册设备
- 如果还是提示，检查账号是否真的是付费账号
- 在 Xcode 中重新选择 Team

### Q4: 应用仍然只能运行 7 天

**可能原因**：
1. 账号未正确识别为付费账号
2. 使用了错误的 Provisioning Profile

**解决**：
1. 检查账号状态：Xcode → Settings → Accounts
2. 确保显示 "Apple Developer Program"
3. 在项目中：取消勾选 "Automatically manage signing"
4. 手动选择正确的 Provisioning Profile（付费账号的）

---

## 🎯 快速检查清单

- [ ] 已在 Xcode Settings → Accounts 中登录账号
- [ ] 账号显示 "Apple Developer Program"（付费）
- [ ] 在项目 Signing 中选择了正确的 Team
- [ ] Bundle Identifier 已设置且唯一
- [ ] 没有红色错误提示

---

## 📞 需要帮助？

如果遇到问题：
1. **检查账号状态**：https://developer.apple.com/account
2. **查看 Xcode 日志**：Window → Devices and Simulators → View Device Logs
3. **清理构建**：Product → Clean Build Folder（Shift + Cmd + K）

---

**配置完成后，应用就可以独立运行 1 年了！** 🎉

