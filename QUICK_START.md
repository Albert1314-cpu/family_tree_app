# 🚀 云同步功能快速开始指南

## ✅ 配置已完成

恭喜！您的Firebase云同步功能已经配置完成，包括：
- ✅ Firebase项目创建
- ✅ Android应用注册
- ✅ google-services.json配置
- ✅ Firebase SDK集成
- ✅ 依赖包安装

## 📱 如何使用云同步功能

### 1. 用户登录

在您的应用中，用户需要先登录才能使用云同步功能。

**在任何界面中添加登录入口：**

```dart
import 'package:flutter/material.dart';
import 'package:family_tree_app/screens/login_screen.dart';
import 'package:family_tree_app/services/cloud_sync_service.dart';

// 检查登录状态
final syncService = CloudSyncService();
if (!syncService.isLoggedIn) {
  // 跳转到登录页面
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
  );
}
```

### 2. 同步数据到云端

**上传家族树和成员数据：**

```dart
import 'package:family_tree_app/services/cloud_sync_service.dart';

final syncService = CloudSyncService();

// 方法1：一次性同步所有数据
await syncService.syncToCloud(familyTree, members);

// 方法2：分别上传
await syncService.uploadFamilyTree(familyTree);
for (var member in members) {
  await syncService.uploadMember(familyTree.id, member);
}
```

### 3. 从云端下载数据

**下载并恢复数据：**

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
  // 保存到本地数据库
}
```

### 4. 实时监听数据变化

**监听其他设备的更新：**

```dart
// 监听家族树变化
syncService.watchFamilyTrees().listen((trees) {
  setState(() {
    _familyTrees = trees;
  });
});
```

### 5. 分享家族树

**生成分享码并分享：**

```dart
import 'package:family_tree_app/screens/share_family_tree_screen.dart';

// 跳转到分享页面
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ShareFamilyTreeScreen(familyTree: familyTree),
  ),
);
```

## 🎯 在现有界面中集成

### 在设置页面添加云同步选项

修改 `lib/screens/settings_screen.dart`，添加以下功能：

```dart
// 添加登录/登出按钮
ListTile(
  leading: Icon(Icons.cloud),
  title: Text('云同步'),
  subtitle: Text(syncService.isLoggedIn ? '已登录' : '未登录'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {
    if (syncService.isLoggedIn) {
      // 显示同步选项
      _showSyncOptions();
    } else {
      // 跳转到登录页面
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  },
),

// 添加同步按钮
ListTile(
  leading: Icon(Icons.sync),
  title: Text('立即同步'),
  subtitle: Text('将数据同步到云端'),
  onTap: () async {
    if (!syncService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先登录')),
      );
      return;
    }
    
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
    
    // 执行同步
    final success = await syncService.syncToCloud(familyTree, members);
    
    Navigator.pop(context); // 关闭加载指示器
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '同步成功！' : '同步失败，请重试'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  },
),
```

### 在家族树详情页添加分享按钮

修改 `lib/screens/family_tree_detail_screen.dart`：

```dart
// 在AppBar中添加分享按钮
AppBar(
  title: Text(familyTree.name),
  actions: [
    IconButton(
      icon: Icon(Icons.share),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShareFamilyTreeScreen(familyTree: familyTree),
          ),
        );
      },
    ),
  ],
),
```

### 在主页添加云同步状态指示器

修改 `lib/screens/home_screen.dart`：

```dart
// 在AppBar中显示云同步状态
AppBar(
  title: Text('族谱制作'),
  actions: [
    // 云同步状态图标
    StreamBuilder<bool>(
      stream: syncService.premiumStatusStream,
      builder: (context, snapshot) {
        final isLoggedIn = syncService.isLoggedIn;
        return IconButton(
          icon: Icon(
            isLoggedIn ? Icons.cloud_done : Icons.cloud_off,
            color: isLoggedIn ? Colors.green : Colors.grey,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          },
        );
      },
    ),
  ],
),
```

## 🔄 自动同步策略

### 在数据变更时自动同步

```dart
// 添加成员时自动同步
Future<void> addMember(Member member) async {
  // 1. 保存到本地数据库
  await databaseService.insertMember(member);
  
  // 2. 如果已登录，同步到云端
  if (syncService.isLoggedIn) {
    await syncService.uploadMember(familyTreeId, member);
  }
  
  // 3. 更新UI
  notifyListeners();
}

// 更新成员时自动同步
Future<void> updateMember(Member member) async {
  await databaseService.updateMember(member);
  
  if (syncService.isLoggedIn) {
    await syncService.uploadMember(familyTreeId, member);
  }
  
  notifyListeners();
}

// 删除成员时同步
Future<void> deleteMember(String memberId) async {
  await databaseService.deleteMember(memberId);
  
  if (syncService.isLoggedIn) {
    // 在云端也删除
    // 可以添加删除方法到CloudSyncService
  }
  
  notifyListeners();
}
```

### 应用启动时自动同步

在 `main.dart` 中：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Firebase
  await Firebase.initializeApp();
  
  // 初始化云同步服务
  final syncService = CloudSyncService();
  await syncService.initialize();
  
  // 如果已登录，尝试同步数据
  if (syncService.isLoggedIn) {
    // 在后台同步，不阻塞应用启动
    _syncInBackground();
  }
  
  runApp(const FamilyTreeApp());
}

void _syncInBackground() async {
  try {
    final syncService = CloudSyncService();
    final trees = await syncService.downloadFamilyTrees();
    print('后台同步完成，获取到 ${trees.length} 个家族树');
  } catch (e) {
    print('后台同步失败: $e');
  }
}
```

## 📊 监控同步状态

### 创建同步状态指示器

```dart
class SyncStatusIndicator extends StatefulWidget {
  @override
  _SyncStatusIndicatorState createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  final syncService = CloudSyncService();
  bool _isSyncing = false;
  
  @override
  Widget build(BuildContext context) {
    if (!syncService.isLoggedIn) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isSyncing ? Colors.blue[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSyncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.cloud_done, size: 16, color: Colors.green),
          SizedBox(width: 6),
          Text(
            _isSyncing ? '同步中...' : '已同步',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

## 🧪 测试功能

### 测试步骤

1. **运行应用**：
   ```bash
   flutter run
   ```

2. **测试登录**：
   - 打开应用
   - 进入设置或点击云同步按钮
   - 使用邮箱注册/登录
   - 或选择匿名登录

3. **测试数据同步**：
   - 创建一个家族树
   - 添加几个成员
   - 点击同步按钮
   - 在Firebase Console中查看数据

4. **测试多设备同步**：
   - 在另一台设备上登录相同账户
   - 查看是否能看到同步的数据

5. **测试分享功能**：
   - 生成分享码
   - 在另一个账户中输入分享码
   - 查看是否能访问家族树

## 🔍 调试技巧

### 查看Firebase日志

```dart
// 在需要调试的地方添加日志
print('开始同步数据...');
final result = await syncService.syncToCloud(familyTree, members);
print('同步结果: $result');
```

### 查看Firebase Console

1. 打开 [Firebase Console](https://console.firebase.google.com/)
2. 选择您的项目
3. 查看各个服务的数据：
   - **Authentication** → 查看用户列表
   - **Firestore Database** → 查看存储的数据
   - **Storage** → 查看上传的照片

## ⚠️ 注意事项

1. **测试模式安全规则**：
   - 当前使用测试模式，任何人都可以读写数据
   - 上线前必须修改为生产环境的安全规则

2. **网络连接**：
   - 确保设备有网络连接
   - 首次同步可能需要较长时间

3. **数据冲突**：
   - 多设备同时编辑可能导致数据冲突
   - Firebase使用"最后写入获胜"策略

4. **费用控制**：
   - 免费额度足够开发和小规模使用
   - 监控使用量，避免超出免费额度

## 🎉 完成！

现在您的家族树应用已经具备完整的云同步功能！用户可以：
- ✅ 在多个设备间同步数据
- ✅ 分享家族树给其他用户
- ✅ 云端备份数据
- ✅ 实时查看更新

如有问题，请参考 `CLOUD_SYNC_GUIDE.md` 获取更详细的技术文档。

