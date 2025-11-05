# 🔧 Firestore 规则 - 最终修复版

## 问题分析

访问分享家族树需要以下权限：
1. ✅ 读取 `shared_trees/{shareCode}` 文档
2. ✅ 读取 `users/{ownerId}/family_trees/{treeId}` 文档（关键！）
3. ✅ 写入 `collaborative_trees/{treeId}/collaborators/{userId}` 文档

**当前规则可能缺少第 2 项的权限！**

## ✅ 正确的规则（复制这个）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ⚠️ 关键：允许读取其他用户的家族树文档（用于分享）
    match /users/{ownerId}/family_trees/{treeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == ownerId;
    }
    
    // 允许访问协作家族树的成员
    match /users/{ownerId}/family_trees/{treeId}/members/{memberId} {
      allow read, write: if request.auth != null;
    }
    
    // 分享链接（允许所有登录用户读取）
    match /shared_trees/{shareId} {
      allow read, write: if request.auth != null;
    }
    
    // 协作者列表（允许所有登录用户管理）
    match /collaborative_trees/{treeId}/collaborators/{collaboratorId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📋 操作步骤

### 1. 打开 Firebase Console
直接访问：**https://console.firebase.google.com/project/family-tree-app/firestore/rules**

### 2. 复制上面的规则
**完整复制**，包括所有代码块

### 3. 替换现有规则
1. 点击规则编辑器
2. **全选并删除**所有现有内容
3. **粘贴**新规则

### 4. 发布
1. 点击 **"发布"** 按钮
2. 等待看到成功提示

### 5. 等待生效
- 等待 **30-60 秒**
- 规则会在全球服务器同步

### 6. 测试
1. 在应用中按 `r` 热重载（或重启应用）
2. 再次尝试输入分享码：`HxUtW34rDC4OJZs0wn2M`
3. 应该可以成功访问

## 🔍 关键区别

**旧规则可能缺少：**
```javascript
// ❌ 缺少这个！
match /users/{ownerId}/family_trees/{treeId} {
  allow read: if request.auth != null;
}
```

**新规则包含：**
```javascript
// ✅ 有了这个！
match /users/{ownerId}/family_trees/{treeId} {
  allow read: if request.auth != null;  // 允许读取家族树元数据
  allow write: if request.auth != null && request.auth.uid == ownerId;  // 只有拥有者可以修改
}
```

## ⚠️ 注意事项

1. **必须完全替换**旧规则，不要保留任何旧代码
2. **确保格式正确**，包括所有大括号和分号
3. **发布后等待**至少 30 秒再测试
4. **确保用户已登录**，规则要求 `request.auth != null`

## 🎯 验证检查清单

- [ ] 规则已完全替换
- [ ] 点击了"发布"按钮
- [ ] 看到了发布成功提示
- [ ] 等待了至少 30 秒
- [ ] 应用已重新加载
- [ ] 用户已登录
- [ ] 再次测试分享码

完成这些步骤后，权限错误应该消失！

