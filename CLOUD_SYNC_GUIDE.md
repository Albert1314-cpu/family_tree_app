# 跨设备数据同步功能使用指南

## 功能概述

您的家庭树应用现在支持跨设备数据同步功能，不同手机的用户可以：
- ✅ 将数据同步到云端
- ✅ 在多个设备间同步数据
- ✅ 分享家族树给其他用户
- ✅ 实时查看家族树更新

## 技术方案

### 使用的技术栈
- **Firebase Authentication** - 用户认证
- **Cloud Firestore** - 数据存储和实时同步
- **Firebase Storage** - 照片存储

### 数据同步方式
1. **实时同步** - 数据变更自动同步到所有设备
2. **离线支持** - 无网络时可继续使用，联网后自动同步
3. **冲突解决** - 自动处理多设备同时编辑的冲突

## 配置步骤

### 1. 创建Firebase项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击"添加项目"
3. 输入项目名称：`family-tree-app`
4. 选择是否启用Google Analytics（可选）
5. 创建项目

### 2. 添加Android应用

1. 在Firebase项目中点击"添加应用" → 选择Android
2. 填写应用信息：
   - **Android包名**：`com.familytree.app`
   - **应用昵称**：族谱制作
   - **调试签名证书SHA-1**（可选）

3. 下载 `google-services.json` 文件
4. 将文件放到：`android/app/google-services.json`

### 3. 配置Android项目

**修改 `android/build.gradle`：**
```gradle
buildscript {
    dependencies {
        // 添加这一行
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**修改 `android/app/build.gradle`：**
```gradle
// 在文件最后添加
apply plugin: 'com.google.gms.google-services'
```

### 4. 启用Firebase服务

在Firebase Console中启用以下服务：

**Authentication（身份验证）：**
1. 进入 Authentication → Sign-in method
2. 启用以下登录方式：
   - 电子邮件/密码
   - 匿名登录

**Firestore Database（数据库）：**
1. 进入 Firestore Database
2. 创建数据库
3. 选择"测试模式"（开发阶段）
4. 选择服务器位置（推荐：asia-east1）

**Storage（存储）：**
1. 进入 Storage
2. 开始使用
3. 选择"测试模式"（开发阶段）

### 5. 配置安全规则

**Firestore规则：**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 分享的家族树
    match /shared_trees/{shareId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

**Storage规则：**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 使用方法

### 1. 用户登录

**邮箱登录：**
```dart
// 在应用中导航到登录页面
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => LoginScreen()),
);
```

**匿名登录（快速开始）：**
- 用户无需注册即可使用
- 数据仍会同步到云端
- 后续可以升级为正式账户

### 2. 同步数据到云端

```dart
final syncService = CloudSyncService();

// 上传家族树
await syncService.uploadFamilyTree(familyTree);

// 上传成员
for (var member in members) {
  await syncService.uploadMember(familyTree.id, member);
}

// 或者一次性同步所有数据
await syncService.syncToCloud(familyTree, members);
```

### 3. 从云端下载数据

```dart
// 下载所有家族树
final trees = await syncService.downloadFamilyTrees();

// 下载特定家族树的成员
final members = await syncService.downloadMembers(familyTreeId);

// 完整同步
final data = await syncService.syncFromCloud(familyTreeId);
if (data != null) {
  final familyTree = data['familyTree'];
  final members = data['members'];
}
```

### 4. 实时监听数据变化

```dart
// 监听家族树变化
syncService.watchFamilyTrees().listen((trees) {
  // 更新UI
  setState(() {
    _familyTrees = trees;
  });
});
```

### 5. 分享家族树

```dart
// 生成分享码
final shareCode = await syncService.shareFamilyTree(familyTreeId);

// 分享给其他用户
// 其他用户输入分享码访问
final sharedTree = await syncService.accessSharedTree(shareCode);
```

## 数据结构

### Firestore数据结构
```
users/
  {userId}/
    family_trees/
      {treeId}/
        - id
        - name
        - description
        - createdAt
        - updatedAt
        
        members/
          {memberId}/
            - id
            - name
            - gender
            - birthDate
            - photoUrl
            - ...

shared_trees/
  {shareId}/
    - ownerId
    - familyTreeId
    - createdAt
    - expiresAt
```

### Storage结构
```
users/
  {userId}/
    family_trees/
      {treeId}/
        photos/
          {memberId}.jpg
```

## 功能特性

### 1. 多设备同步
- 用户在设备A添加成员
- 数据自动同步到云端
- 设备B实时接收更新

### 2. 离线模式
- 无网络时可继续使用
- 数据保存在本地
- 联网后自动同步

### 3. 照片同步
- 照片自动上传到云存储
- 支持高清照片
- 自动生成缩略图

### 4. 分享功能
- 生成6位分享码
- 有效期30天
- 只读访问权限

### 5. 数据安全
- 用户数据隔离
- 加密传输
- 访问权限控制

## 费用说明

### Firebase免费额度（Spark计划）

**Firestore：**
- 存储：1 GB
- 文档读取：50,000/天
- 文档写入：20,000/天
- 文档删除：20,000/天

**Storage：**
- 存储：5 GB
- 下载：1 GB/天
- 上传：无限制

**Authentication：**
- 用户数：无限制
- 认证次数：无限制

### 对于家庭树应用
- 免费额度足够支持数千用户
- 超出后按使用量付费
- 建议监控使用量

## 最佳实践

### 1. 定期同步
```dart
// 在应用启动时同步
void initState() {
  super.initState();
  _syncFromCloud();
}

// 在数据变更时同步
void _addMember(Member member) {
  // 本地保存
  _localDatabase.insertMember(member);
  
  // 云端同步
  _syncService.uploadMember(familyTreeId, member);
}
```

### 2. 处理同步错误
```dart
try {
  await syncService.syncToCloud(familyTree, members);
} catch (e) {
  // 显示错误提示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('同步失败，请检查网络连接')),
  );
  
  // 稍后重试
  Future.delayed(Duration(minutes: 5), () {
    _retrySync();
  });
}
```

### 3. 优化照片上传
```dart
// 压缩照片后上传
final compressedImage = await compressImage(originalImage);
await syncService.uploadPhoto(familyTreeId, memberId, compressedImage);
```

### 4. 批量操作
```dart
// 批量上传多个成员
final batch = _firestore.batch();
for (var member in members) {
  final docRef = _firestore.collection('members').doc(member.id);
  batch.set(docRef, member.toJson());
}
await batch.commit();
```

## 常见问题

### Q: 数据同步需要多长时间？
A: 通常在1-3秒内完成，取决于网络速度和数据量。

### Q: 离线时能使用吗？
A: 可以，所有数据都会保存在本地，联网后自动同步。

### Q: 多个设备同时编辑会冲突吗？
A: Firestore会自动处理冲突，使用"最后写入获胜"策略。

### Q: 照片会占用很多流量吗？
A: 首次同步会下载所有照片，之后只同步新增照片。建议在WiFi下同步。

### Q: 如何删除云端数据？
A: 在设置中选择"删除账户和数据"，或在Firebase Console中手动删除。

## 下一步

1. **完成Firebase配置**
2. **测试登录功能**
3. **测试数据同步**
4. **测试分享功能**
5. **优化用户体验**

## 技术支持

如有问题，请查看：
- [Firebase文档](https://firebase.google.com/docs)
- [Flutter Firebase插件](https://firebase.flutter.dev)
- [项目GitHub Issues](您的项目地址)

