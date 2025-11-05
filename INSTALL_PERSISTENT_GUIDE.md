# 🔒 解决 iPhone 应用拔线后无法使用的问题

## ❌ 问题原因

使用**免费 Apple ID** 开发模式安装的应用：
- ⚠️ 应用有效期只有 **7 天**
- ⚠️ 需要定期重新签名
- ⚠️ 拔掉数据线后可能无法运行（特别是首次安装后）

## ✅ 解决方案

### 方案一：重新签名应用（最简单，但需定期操作）

#### 方法 A：使用 Xcode 重新签名

1. **连接 iPhone 到 Mac**
2. **打开 Xcode**：
   ```bash
   open "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios/Runner.xcworkspace"
   ```
3. **在 Xcode 中**：
   - 选择项目 **Runner**（左侧）
   - 选择 **Signing & Capabilities**
   - 确保勾选了 **Automatically manage signing**
   - 选择你的 **Team**
4. **重新安装**：
   - 点击运行按钮（▶️）或按 `Cmd + R`
   - 或者：**Product → Run**

#### 方法 B：使用 Flutter 命令

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
flutter run
```

#### 方法 C：在 iPhone 上重新信任

如果应用已过期：
1. iPhone：**设置 → 通用 → VPN与设备管理**
2. 找到你的开发者证书
3. 点击 **信任**（如果已过期，需要重新连接 Mac 签名）

---

### 方案二：构建 Ad Hoc 版本（推荐，应用可独立运行）

这种方式构建的应用可以独立运行，不需要连接 Mac。

#### 步骤 1：获取设备 UDID

```bash
# 方法一：使用 Xcode
# 打开 Xcode → Window → Devices and Simulators
# 选择你的 iPhone，查看 UDID

# 方法二：使用命令行
xcrun xctrace list devices
```

#### 步骤 2：在 Apple Developer 注册设备

1. 访问：https://developer.apple.com/account/resources/devices/list
2. 登录你的 Apple ID
3. 点击 **+** 添加设备
4. 输入设备名称和 UDID
5. 保存

#### 步骤 3：创建 Provisioning Profile

1. 访问：https://developer.apple.com/account/resources/profiles/list
2. 点击 **+** 创建新 Profile
3. 选择 **Ad Hoc**
4. 选择你的 App ID
5. 选择证书
6. **选择你的 iPhone 设备**（重要！）
7. 下载 Profile

#### 步骤 4：在 Xcode 中配置

1. 打开项目：
   ```bash
   open "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios/Runner.xcworkspace"
   ```

2. 配置签名：
   - 选择项目 **Runner**
   - **Signing & Capabilities**
   - 取消勾选 **Automatically manage signing**
   - 选择 **Provisioning Profile** → 选择你刚创建的 Ad Hoc Profile

#### 步骤 5：构建并导出

1. **选择设备**：顶部选择 **Any iOS Device (arm64)**
2. **构建 Archive**：**Product → Archive**
3. **等待构建完成**
4. **在 Organizer 窗口**：
   - 选择刚创建的 Archive
   - 点击 **Distribute App**
   - 选择 **Ad Hoc**
   - 选择 **Export**
   - 选择保存位置

#### 步骤 6：安装到 iPhone

**方法 A：使用 Xcode**
1. 在 Organizer 中选择 Archive
2. **Distribute App → Ad Hoc → Export**
3. 导出后，在 Finder 中找到 `.ipa` 文件
4. 使用 Xcode → Window → Devices and Simulators
5. 选择你的 iPhone，拖拽 `.ipa` 文件安装

**方法 B：使用第三方工具**
- **Apple Configurator 2**（Mac App Store 免费）
- **3uTools**（Windows/Mac，免费）
- **iMazing**（付费，功能强大）

---

### 方案三：使用 TestFlight（适合测试分发）

这是最推荐的方式，应用可以运行 90 天，无需设备 UDID。

#### 步骤 1：准备 App Store Connect

1. 访问：https://appstoreconnect.apple.com/
2. 登录你的 Apple ID
3. 创建新应用（如果还没有）
4. 记录 **Bundle ID**（必须与项目中的一致）

#### 步骤 2：配置 Bundle ID

1. 打开 Xcode 项目
2. 选择项目 → **Signing & Capabilities**
3. 确保 Bundle Identifier 与 App Store Connect 中的一致

#### 步骤 3：上传到 TestFlight

```bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"

# 构建 Release 版本
flutter build ios --release
```

在 Xcode：
1. **Product → Archive**
2. **Distribute App → App Store Connect**
3. **Upload**
4. 等待上传完成

#### 步骤 4：在 App Store Connect 配置

1. 进入你的应用
2. 点击 **TestFlight** 标签
3. 添加**内部测试人员**（你的 Apple ID）
4. 等待处理完成（通常几分钟）

#### 步骤 5：在 iPhone 上安装

1. 在 iPhone 上下载 **TestFlight** App（App Store）
2. 打开 TestFlight
3. 接受邀请（如果收到邮件）
4. 点击 **安装** 应用

**优点**：
- ✅ 应用可以运行 **90 天**
- ✅ 无需连接 Mac
- ✅ 可以分发给其他测试用户
- ✅ 自动更新

---

### 方案四：升级到付费 Developer 账号（最佳方案）

**价格**：$99/年（约 ¥700/年）

**优点**：
- ✅ 应用有效期更长（1年）
- ✅ 可以安装到任何设备
- ✅ 可以发布到 App Store
- ✅ 更好的技术支持

**注册**：
1. 访问：https://developer.apple.com/programs/
2. 点击 **Enroll**
3. 使用 Apple ID 登录
4. 完成支付

---

## 🎯 快速解决方案（临时）

### 如果应用突然无法打开：

1. **重新连接 iPhone 到 Mac**
2. **重新运行**：
   ```bash
   cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
   flutter run
   ```
3. **在 iPhone 上重新信任**：
   - **设置 → 通用 → VPN与设备管理**
   - 找到开发者证书，点击 **信任**

---

## 📊 方案对比

| 方案 | 有效期 | 是否需要 Mac | 是否需要付费 | 难度 |
|------|--------|--------------|--------------|------|
| 开发模式（免费） | 7天 | ✅ 需要 | ❌ 免费 | ⭐ 简单 |
| Ad Hoc | 1年 | ✅ 需要 | ❌ 免费 | ⭐⭐ 中等 |
| TestFlight | 90天 | ✅ 需要 | ❌ 免费 | ⭐⭐ 中等 |
| 付费 Developer | 1年 | ❌ 不需要 | ✅ $99/年 | ⭐ 简单 |

## 💡 推荐方案

1. **短期测试**：使用开发模式，定期重新签名
2. **长期使用**：使用 TestFlight 或 Ad Hoc
3. **正式发布**：升级到付费 Developer 账号

---

## 🔧 常见问题

### Q1: 应用显示"未受信任"

**解决**：
1. iPhone：**设置 → 通用 → VPN与设备管理**
2. 找到你的开发者证书
3. 点击 **信任**

### Q2: 应用安装后立即闪退

**原因**：签名过期或证书无效

**解决**：
1. 重新连接 Mac
2. 在 Xcode 中重新签名
3. 重新安装

### Q3: 如何检查应用有效期

**方法**：
1. iPhone：**设置 → 通用 → VPN与设备管理**
2. 查看开发者证书的到期时间

### Q4: 可以延长免费签名的有效期吗？

**不行**，免费账号的限制是 Apple 设定的，无法绕过。

**建议**：
- 使用 TestFlight（90天有效期）
- 或升级到付费账号

---

## 📝 一键重新签名脚本

创建脚本文件 `reinstall.sh`：

```bash
#!/bin/bash
cd "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app"
echo "正在重新签名并安装..."
flutter run
```

使用方法：
```bash
chmod +x reinstall.sh
./reinstall.sh
```

---

**选择最适合你的方案，享受持久可用的应用！** 🎉

