# Firestore 安全规则 - 简化版本（立即使用）

## ⚡ 快速修复权限问题

### 步骤 1: 打开 Firebase Console
访问：https://console.firebase.google.com/project/family-tree-app-65215/firestore/rules

### 步骤 2: 复制以下规则

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 允许登录用户访问自己的数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 允许所有登录用户读取其他用户的家族树成员（用于协作）
    match /users/{ownerId}/family_trees/{treeId}/members/{memberId} {
      allow read, write: if request.auth != null;
    }
    
    // 允许所有登录用户读取和创建分享链接
    match /shared_trees/{shareId} {
      allow read, write: if request.auth != null;
    }
    
    // 允许所有登录用户管理协作者
    match /collaborative_trees/{treeId}/collaborators/{collaboratorId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 步骤 3: 粘贴并发布
1. 删除编辑器中的所有现有规则
2. 粘贴上面的规则
3. 点击 **"发布"** 按钮
4. 等待 30-60 秒

## ✅ 验证

发布后：
1. 等待 1 分钟
2. 在应用中按 `r` 热重载（或重新打开应用）
3. 再次尝试分享功能

## ⚠️ 说明

这些规则比较宽松，适合：
- ✅ 开发和测试阶段
- ✅ 小规模使用
- ✅ 内部协作使用

**不适合：**
- ❌ 大规模公开应用
- ❌ 需要严格权限控制的场景

## 🔒 生产环境建议

上线前，建议使用 `FIRESTORE_RULES_SETUP.md` 中提供的更严格规则。

