# Firestore 安全规则配置指南

## 🔴 问题

遇到错误：`[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.`

这是因为 Firestore 的安全规则限制了协作功能的访问。

## ✅ 解决方案

### 步骤 1: 打开 Firebase Console

1. 访问：https://console.firebase.google.com/
2. 选择项目：**family-tree-app**

### 步骤 2: 进入 Firestore Database

1. 在左侧导航栏点击 **"Firestore Database"**
2. 点击顶部标签栏的 **"规则"** (Rules) 标签

### 步骤 3: 更新安全规则

复制以下规则，替换现有的规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 允许访问其他用户的家族树（用于协作）
    // 协作者可以读取协作家族树的数据
    match /users/{ownerId}/family_trees/{treeId}/members/{memberId} {
      allow read: if request.auth != null;
      // 允许协作者写入
      allow write: if request.auth != null;
    }
    
    // 分享的家族树
    match /shared_trees/{shareId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
    }
    
    // 协作家族树信息
    match /collaborative_trees/{treeId}/collaborators/{collaboratorId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 步骤 4: 发布规则

1. 点击 **"发布"** (Publish) 按钮
2. 等待几秒钟，规则生效

## 🔒 规则说明

### 1. 用户数据访问 (`/users/{userId}`)
- 用户只能访问自己的数据
- 需要登录

### 2. 协作家族树成员 (`/users/{ownerId}/family_trees/{treeId}/members`)
- **读取**：任何登录用户都可以读取（用于查看协作家族树）
- **写入**：任何登录用户都可以写入（用于添加成员）

### 3. 分享链接 (`/shared_trees/{shareId}`)
- **读取**：任何登录用户都可以读取分享信息
- **创建**：只能创建自己的分享链接
- **更新/删除**：只有创建者可以操作

### 4. 协作者列表 (`/collaborative_trees/{treeId}/collaborators`)
- **读取**：任何登录用户都可以读取
- **写入**：任何登录用户都可以写入（添加自己为协作者）

## ⚠️ 注意

### 开发阶段（当前设置）
上述规则比较宽松，适合开发和测试。**所有登录用户都可以：**
- 读取任何协作家族树的成员
- 向协作家族树添加成员

### 生产环境（上线前）
如果您要上线应用，建议使用更严格的安全规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 协作家族树成员（仅协作者可访问）
    match /users/{ownerId}/family_trees/{treeId}/members/{memberId} {
      // 检查是否是协作者
      allow read, write: if request.auth != null && (
        request.auth.uid == ownerId ||
        exists(/databases/$(database)/documents/collaborative_trees/$(treeId)/collaborators/$(request.auth.uid))
      );
    }
    
    // 分享链接
    match /shared_trees/{shareId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
    }
    
    // 协作者列表
    match /collaborative_trees/{treeId}/collaborators/{collaboratorId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == collaboratorId;
      allow delete: if request.auth != null && (
        request.auth.uid == collaboratorId ||
        exists(/databases/$(database)/documents/users/$(request.auth.uid)/family_trees/$(treeId))
      );
    }
  }
}
```

## ✅ 验证规则

更新规则后：

1. **等待 1-2 分钟**让规则生效
2. 重新运行应用
3. 尝试分享家族树功能
4. 检查错误是否消失

## 📝 快速操作步骤总结

1. 打开：https://console.firebase.google.com/
2. 选择项目：family-tree-app
3. Firestore Database → 规则标签
4. 复制上面的规则代码
5. 点击"发布"
6. 等待生效，重新测试应用

完成后，多人协作功能应该可以正常工作了！

