# 🔍 检查账号类型指南

## 📊 你的账号信息

从截图看到：
- **Email**: 995085987@qq.com
- **Team**: changfa xiao
- **Role**: Admin

## 🔎 如何判断账号类型

### 方法一：查看 Team 类型（在 Xcode 中）

在 Xcode → Settings → Accounts 中：

1. **点击你的账号**（995085987@qq.com）
2. **查看右侧 Team 列表**
3. **检查显示内容**：

#### ✅ 付费账号（Apple Developer Program）
- 显示：**Apple Developer Program** 或 **Apple Development**
- Team 名称可能是：你的名字 或 公司名称
- 显示有效期限：如 "Valid until 2025-XX-XX"

#### ❌ 免费账号（Personal Team）
- 显示：**Personal Team**
- Team 名称：你的名字
- 不显示有效期

---

### 方法二：在线检查

1. **访问**：https://developer.apple.com/account
2. **登录**你的 Apple ID
3. **查看页面**：

#### ✅ 如果是付费账号：
- 会显示 "Apple Developer Program" 徽章
- 显示会员有效期
- 可以访问完整功能

#### ❌ 如果是免费账号：
- 只能访问有限功能
- 会提示需要加入 Apple Developer Program

---

### 方法三：在项目签名中检查

1. **打开项目**：
   ```bash
   open "/Users/xiaochangfa/Desktop/安卓苹果/family_tree_app/ios/Runner.xcworkspace"
   ```

2. **选择项目** → **Signing & Capabilities**
3. **查看 Team 下拉菜单**：

#### ✅ 付费账号：
- 显示：**changfa xiao (Apple Developer Program)**
- 或显示：**changfa xiao (Apple Development)**

#### ❌ 免费账号：
- 显示：**changfa xiao (Personal Team)**

---

## 🎯 根据你的情况判断

从你的截图看：
- **Team**: changfa xiao
- **Role**: Admin

**可能的情况**：

### 情况 1：付费账号但显示简化
- 如果显示 "Apple Developer Program"，说明是付费账号 ✅
- 应用有效期 1 年

### 情况 2：免费账号
- 如果显示 "Personal Team"，说明是免费账号 ❌
- 应用有效期只有 7 天

---

## 💡 如何确认

### 快速检查命令：

在终端运行：
```bash
# 检查 Xcode 中的账号信息
defaults read com.apple.dt.Xcode | grep -i developer
```

或者：

1. **在 Xcode 中**：
   - Settings → Accounts
   - 点击你的账号
   - **查看右侧详细信息**
   - 看是否有 "Apple Developer Program" 字样

2. **在项目签名中**：
   - 打开项目 → Signing & Capabilities
   - 查看 Team 下拉菜单
   - 看是否显示 "Apple Developer Program"

---

## 🔧 如果是免费账号，如何升级

### 步骤 1：访问注册页面

1. 访问：https://developer.apple.com/programs/
2. 点击 **Enroll**
3. 使用你的 Apple ID 登录

### 步骤 2：完成注册

1. 填写个人信息
2. 选择账号类型（个人/公司）
3. 完成支付（$99/年，约 ¥700/年）

### 步骤 3：激活账号

1. 支付完成后，等待审核（通常几分钟到几小时）
2. 在 Xcode → Settings → Accounts 中刷新
3. 应该会显示 "Apple Developer Program"

---

## 📝 账号类型对比

| 特性 | 免费账号（Personal Team） | 付费账号（Developer Program） |
|------|--------------------------|------------------------------|
| 年费 | 免费 | $99/年 |
| 应用有效期 | 7 天 | 1 年 |
| 设备限制 | 最多 3 台 | 无限制 |
| App Store | ❌ 不能发布 | ✅ 可以发布 |
| TestFlight | ❌ 不能使用 | ✅ 可以使用 |
| 独立运行 | ❌ 需要定期连接 Mac | ✅ 可以独立运行 |

---

## 🎯 下一步操作

### 如果是付费账号 ✅：
1. 在项目签名中选择你的 Team
2. 构建并安装应用
3. 应用可以独立运行 1 年

### 如果是免费账号 ❌：
1. 选择升级到付费账号（推荐）
2. 或使用 TestFlight（需要付费账号）
3. 或定期重新签名（每 7 天）

---

**请告诉我你的账号显示的是 "Apple Developer Program" 还是 "Personal Team"，我可以进一步帮你！** 🔍

