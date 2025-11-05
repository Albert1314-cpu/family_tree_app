# ✅ 解决 "PLA Update available" 错误

## ❌ 错误信息

```
Error Domain=DeveloperAPIServiceErrorDomain Code=5 
"Unable to process request - PLA Update available"

You currently don't have access to this membership resource. 
To resolve this issue, agree to the latest Program License Agreement 
in your developer account.
```

## 🔍 问题原因

这是 Apple 更新了开发者计划许可协议（Program License Agreement），需要你重新同意。

## ✅ 解决方案（非常简单）

### 步骤 1：访问 Apple Developer 网站

1. **打开浏览器**
2. **访问**：https://developer.apple.com/account
3. **使用你的账号登录**（995085987@qq.com）

### 步骤 2：同意许可协议

登录后，会出现以下情况之一：

#### 情况 A：自动弹出协议窗口
- 页面上会显示一个协议对话框
- 阅读协议内容
- 点击 **"Agree"（同意）** 或 **"同意"** 按钮

#### 情况 B：需要手动查找
1. **查看页面顶部或中间**是否有提示信息
2. **查找链接或按钮**，如：
   - "Review Agreement"（查看协议）
   - "Agree to Terms"（同意条款）
   - "Program License Agreement"（程序许可协议）
3. **点击进入并同意**

#### 情况 C：在账户设置中
1. **点击右上角的账户图标**
2. **选择 "Account"（账户）**
3. **查找 "Agreements"（协议）或 "License"（许可）**
4. **找到未同意的协议并同意**

### 步骤 3：验证同意成功

同意后：
- ✅ 页面会刷新
- ✅ 不再显示协议提示
- ✅ 可以正常访问所有功能

### 步骤 4：回到 Xcode 重新尝试

1. **关闭错误对话框**（点击 "Done"）
2. **在 Xcode → Settings → Accounts 中**：
   - 选择你的账号
   - 点击 **"Download Manual Profiles"** 按钮
   - 或点击刷新按钮
3. **等待下载完成**

---

## 🎯 快速操作链接

**直接访问**：https://developer.apple.com/account

登录后会看到协议提示，点击同意即可。

---

## 📝 详细步骤

### 如果找不到协议入口：

1. **访问**：https://developer.apple.com/account/resources/agreements/list
2. **查看协议列表**
3. **找到状态为 "Action Required"（需要操作）的协议**
4. **点击查看并同意**

---

## ✅ 验证修复

同意协议后，回到 Xcode：

1. **Settings → Accounts**
2. **选择你的账号**
3. **点击 "Download Manual Profiles"**
4. **应该不再出现错误**

然后在项目中：
1. **打开项目** → **Signing & Capabilities**
2. **应该可以正常下载配置文件**
3. **没有红色错误提示**

---

## 💡 常见问题

### Q1: 登录后没有看到协议提示

**可能原因**：
- 已经同意过了
- 需要刷新页面

**解决**：
1. 刷新页面（Cmd + R）
2. 或访问：https://developer.apple.com/account/resources/agreements/list
3. 查看是否有未同意的协议

### Q2: 同意后还是无法下载

**解决**：
1. 等待几分钟（Apple 服务器同步需要时间）
2. 在 Xcode 中重新登录账号：
   - 删除账号
   - 重新添加
3. 清理 Xcode 缓存：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

### Q3: 找不到协议页面

**直接链接**：
- 协议列表：https://developer.apple.com/account/resources/agreements/list
- 账户主页：https://developer.apple.com/account

---

## 🎉 完成后

同意协议后，你的付费账号应该可以正常使用了：
- ✅ 可以下载配置文件
- ✅ 可以创建证书
- ✅ 应用可以独立运行 1 年
- ✅ 可以发布到 App Store

---

**按照上述步骤操作，问题应该就解决了！** 🚀

