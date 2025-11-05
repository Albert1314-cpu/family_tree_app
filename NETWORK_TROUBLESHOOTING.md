# 网络连接问题排查指南

## 🔴 问题描述

遇到以下错误：
- `network-request-failed` - Network error
- DNS 解析超时：`www.googleapis.com:443`
- URL 请求超时：`The request timed out`

## 📋 问题原因分析

### 1. DNS 解析失败
错误信息显示：`Query fired: did not receive all answers in time for www.googleapis.com:443`

**可能的原因：**
- 网络环境限制（公司/学校网络可能有防火墙）
- DNS 服务器配置问题
- VPN 或代理设置问题
- iOS 模拟器网络配置问题

### 2. 网络连接超时
- 请求到 Firebase 服务器的连接被阻塞
- 网络速度过慢
- 防火墙阻止了对 `googleapis.com` 的访问

## 🔧 解决方案

### 方案 1: 检查网络环境

#### 步骤 1: 测试基本网络连接
在 Mac 终端运行：
```bash
# 测试 DNS 解析
nslookup www.googleapis.com

# 测试网络连接
ping www.googleapis.com

# 测试 HTTPS 连接
curl -I https://www.googleapis.com
```

如果这些命令失败，说明是网络环境问题。

#### 步骤 2: 尝试切换网络
1. **关闭 VPN/代理**
   - 如果在使用 VPN，尝试关闭
   - 检查系统代理设置

2. **切换网络**
   - 从 WiFi 切换到移动热点
   - 从企业网络切换到家庭网络

3. **检查防火墙设置**
   - macOS 系统偏好设置 → 安全性与隐私 → 防火墙
   - 确保允许应用网络访问

### 方案 2: iOS 模拟器特定问题

如果使用 iOS 模拟器，可能是模拟器网络配置问题：

#### 方法 1: 重启模拟器
```bash
# 完全关闭模拟器
killall "Simulator"

# 重新启动
open -a Simulator
```

#### 方法 2: 使用真机测试
模拟器有时有网络问题，建议在真实 iOS 设备上测试：
1. 连接 iPhone/iPad 到 Mac
2. 运行：`flutter run`
3. 选择连接的设备

### 方案 3: 检查 DNS 设置

#### macOS 系统 DNS 设置
1. 系统偏好设置 → 网络
2. 选择当前网络连接（WiFi 或以太网）
3. 点击"高级" → "DNS"
4. 添加公共 DNS 服务器：
   - `8.8.8.8` (Google DNS)
   - `8.8.4.4` (Google DNS)
   - `1.1.1.1` (Cloudflare DNS)

### 方案 4: 检查 Firebase 连接

#### 测试 Firebase 可访问性
```bash
# 测试 Firebase Authentication API
curl https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser

# 应该返回 JSON 响应（即使是错误也说明连接正常）
```

### 方案 5: iOS 配置检查

确保 `ios/Runner/Info.plist` 包含正确的网络配置（已自动添加）：
- `NSAppTransportSecurity` 设置
- 允许访问 `googleapis.com` 及其子域名

## 🧪 使用应用内诊断工具

运行应用后，在设置页面：
1. 找到 "Firebase 验证" 部分
2. 点击 "验证 Authentication"
3. 查看详细的网络诊断信息

## 📱 临时解决方案

如果网络问题无法立即解决，可以使用以下临时方案：

### 1. 使用真机而非模拟器
模拟器的网络栈有时有问题，真机通常更稳定。

### 2. 使用移动数据网络
如果 WiFi 网络有防火墙，尝试使用手机热点。

### 3. 检查网络代理设置
```bash
# 检查系统代理
echo $http_proxy
echo $https_proxy

# 如果设置了代理但不可用，清除它们
unset http_proxy
unset https_proxy
```

### 4. 重启网络服务
```bash
# macOS 重启网络
sudo ifconfig en0 down
sudo ifconfig en0 up

# 或重启网络位置
# 系统偏好设置 → 网络 → 位置 → 编辑位置 → 添加新位置
```

## 🔍 诊断步骤总结

1. ✅ **测试基础网络**：能否访问 google.com？
2. ✅ **测试 DNS 解析**：`nslookup www.googleapis.com`
3. ✅ **测试 HTTPS 连接**：`curl https://www.googleapis.com`
4. ✅ **检查防火墙/代理**：是否有网络限制？
5. ✅ **切换网络环境**：尝试不同网络
6. ✅ **使用真机测试**：避免模拟器网络问题
7. ✅ **检查 DNS 设置**：使用公共 DNS 服务器

## 🆘 仍然无法解决？

如果以上方法都无法解决，可能的原因：
1. **企业网络限制**：需要联系网络管理员开放 `*.googleapis.com`
2. **地区网络限制**：某些地区可能限制访问 Google 服务
3. **运营商限制**：某些移动运营商可能限制某些域名

**建议：**
- 使用移动数据网络（4G/5G）测试
- 使用 VPN（如果地区限制）
- 使用真实 iOS 设备而非模拟器

## 📞 获取更多帮助

如果问题持续存在，请提供以下信息：
1. 运行环境（iOS 模拟器版本 / iOS 设备版本）
2. 网络环境（家庭 WiFi / 公司网络 / 移动数据）
3. 是否使用 VPN 或代理
4. 完整的错误日志
5. 网络诊断命令的输出结果

