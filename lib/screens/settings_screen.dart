import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/family_tree.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../services/cloud_sync_service.dart';
import '../providers/family_tree_provider.dart';
import 'family_tree_visualization_screen.dart';
import 'login_screen.dart';
import 'share_family_tree_screen.dart';

class SettingsScreen extends StatefulWidget {
  final FamilyTree familyTree;
  final List<Member> members;
  final List<Relationship> relationships;

  const SettingsScreen({
    super.key,
    required this.familyTree,
    required this.members,
    required this.relationships,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  final _syncService = CloudSyncService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 云同步
          _buildSection(
            title: '云同步',
            children: [
              _buildListTile(
                icon: _syncService.isLoggedIn ? Icons.cloud_done : Icons.cloud_off,
                title: _syncService.isLoggedIn ? '已登录' : '登录账户',
                subtitle: _syncService.isLoggedIn ? '点击查看同步选项' : '登录后可云端同步数据',
                onTap: _handleCloudSync,
              ),
              if (_syncService.isLoggedIn) ...[
                _buildListTile(
                  icon: Icons.sync,
                  title: '立即同步',
                  subtitle: '将数据同步到云端',
                  onTap: _syncToCloud,
                ),
                _buildListTile(
                  icon: Icons.share,
                  title: '分享家族树',
                  subtitle: '生成分享码给其他用户',
                  onTap: _shareFamilyTree,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Firebase 验证
          _buildSection(
            title: 'Firebase 验证',
            children: [
              _buildListTile(
                icon: Icons.verified_user,
                title: '验证 Authentication',
                subtitle: '测试 Firebase 认证配置',
                onTap: _verifyFirebaseAuth,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 数据管理
          _buildSection(
            title: '数据管理',
            children: [
              _buildListTile(
                icon: Icons.file_download,
                title: '导出数据',
                subtitle: '导出为CSV格式',
                onTap: _exportToCSV,
              ),
              _buildListTile(
                icon: Icons.image,
                title: '导出族谱图',
                subtitle: '保存族谱图为图片',
                onTap: _exportTreeImage,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 关于
          _buildSection(
            title: '关于',
            children: [
              _buildListTile(
                icon: Icons.info,
                title: '关于应用',
                subtitle: '族谱制作 v1.0.0',
                onTap: _showAboutDialog,
              ),
              _buildListTile(
                icon: Icons.help,
                title: '使用帮助',
                subtitle: '查看使用说明',
                onTap: _showHelpDialog,
              ),
              _buildListTile(
                icon: Icons.contact_support,
                title: '联系我们',
                subtitle: '反馈问题或建议',
                onTap: _showContactDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // 处理云同步点击
  Future<void> _handleCloudSync() async {
    if (_syncService.isLoggedIn) {
      // 已登录，显示同步选项对话框
      _showSyncOptionsDialog();
    } else {
      // 未登录，跳转到登录页面
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      
      if (result == true && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登录成功！现在可以使用云同步功能'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 显示同步选项对话框
  void _showSyncOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('云同步选项'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('上传到云端'),
              subtitle: const Text('将当前数据同步到云端'),
              onTap: () {
                Navigator.pop(context);
                _syncToCloud();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('从云端下载'),
              subtitle: const Text('下载云端数据到本地'),
              onTap: () {
                Navigator.pop(context);
                _syncFromCloud();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 同步到云端
  Future<void> _syncToCloud() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _syncService.syncToCloud(
        widget.familyTree,
        widget.members,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '同步成功！' : '同步失败，请重试'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 从云端同步
  Future<void> _syncFromCloud() async {
    if (!_syncService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先登录账户'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await _syncService.syncFromCloud(widget.familyTree.id);

      if (mounted) {
        Navigator.pop(context);
        
        if (data != null) {
          final familyTree = data['familyTree'] as FamilyTree;
          final members = data['members'] as List<Member>;
          
          // 保存到本地数据库
          final provider = context.read<FamilyTreeProvider>();
          
          // 检查家族树是否存在，如果不存在则创建，存在则更新
          final exists = provider.familyTrees.any((tree) => tree.id == familyTree.id);
          
          if (exists) {
            await provider.updateFamilyTree(familyTree);
          } else {
            // 如果不存在，需要添加到数据库（使用 Provider 方法）
            await provider.createFamilyTreeWithData(
              familyTree,
              [], // 先创建空树，成员稍后添加
              [],
            );
          }
          
          // 先选择家族树以加载现有成员
          await provider.selectFamilyTree(familyTree);
          
          // 获取现有的本地成员
          final existingMembers = List<Member>.from(provider.members);
          
          // 删除旧的本地成员和关系
          for (final existingMember in existingMembers) {
            if (existingMember.familyTreeId == familyTree.id) {
              try {
                await provider.deleteMember(existingMember.id);
              } catch (e) {
                print('删除旧成员 ${existingMember.name} 失败: $e');
              }
            }
          }
          
          // 使用批量保存方法保存从云端下载的成员（保持原始ID）
          final savedCount = await provider.saveDownloadedMembers(members);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('数据下载成功！已更新 ${savedCount} 个成员'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未找到云端数据，请确保家族树已上传到云端'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        
        String errorMessage = '下载失败: $e';
        if (e.toString().contains('permission-denied')) {
          errorMessage = '权限不足，请确保已在 Firebase Console 配置正确的安全规则';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 分享家族树
  Future<void> _shareFamilyTree() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareFamilyTreeScreen(familyTree: widget.familyTree),
      ),
    );
  }

  // 验证 Firebase Authentication
  Future<void> _verifyFirebaseAuth() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = <String, String>{};
      
      // 1. 测试匿名登录
      try {
        await _syncService.signInAnonymously().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('匿名登录超时'),
        );
        results['匿名登录'] = '✅ 成功';
        
        // 退出匿名登录以便测试其他方式
        await _syncService.signOut();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'operation-not-allowed') {
          results['匿名登录'] = '❌ 未启用（需要在 Firebase Console 启用）';
        } else if (e.code == 'network-request-failed') {
          results['匿名登录'] = '❌ 网络错误：${e.message}';
        } else {
          results['匿名登录'] = '❌ ${e.code}: ${e.message}';
        }
      } catch (e) {
        results['匿名登录'] = '❌ 错误: $e';
      }

      // 2. 测试邮箱注册（使用测试邮箱）
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'test123456';
      
      try {
        await _syncService.signUpWithEmail(testEmail, testPassword).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('邮箱注册超时'),
        );
        results['邮箱注册'] = '✅ 成功';
        
        // 删除测试用户
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'operation-not-allowed') {
          results['邮箱注册'] = '❌ 未启用（需要在 Firebase Console 启用）';
        } else if (e.code == 'network-request-failed') {
          results['邮箱注册'] = '❌ 网络错误：${e.message}';
        } else {
          results['邮箱注册'] = '❌ ${e.code}: ${e.message}';
        }
      } catch (e) {
        results['邮箱注册'] = '❌ 错误: $e';
      }

      // 3. 检查 Firebase 初始化
      try {
        final auth = FirebaseAuth.instance;
        results['Firebase 初始化'] = '✅ 成功';
        results['项目 ID'] = 'family-tree-app-65215';
      } catch (e) {
        results['Firebase 初始化'] = '❌ 失败: $e';
      }

      if (mounted) {
        Navigator.pop(context);
        
        // 显示验证结果
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Firebase Authentication 验证结果'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: results.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: entry.value.startsWith('✅') 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              if (results.values.any((v) => v.contains('未启用')))
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showFirebaseConsoleHelp();
                  },
                  child: const Text('查看帮助'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('验证过程出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示 Firebase Console 帮助
  void _showFirebaseConsoleHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('启用 Firebase Authentication'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '请在 Firebase Console 中启用以下登录方式：\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. 访问 Firebase Console:'),
              Text('   https://console.firebase.google.com/\n'),
              Text('2. 选择项目: family-tree-app\n'),
              Text('3. 进入 Authentication → Sign-in method\n'),
              Text('4. 启用以下登录方式：'),
              Text('   • Email/Password（电子邮件/密码）'),
              Text('   • Anonymous（匿名登录）\n'),
              Text('5. 点击"保存"后重新测试'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 退出登录
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出登录后将无法使用云同步功能，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _syncService.signOut();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已退出登录'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    if (_isExporting) return;
    
    setState(() {
      _isExporting = true;
    });

    try {
      final csvContent = _generateCSVContent();
      
      // 创建临时文件
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${widget.familyTree.name}_族谱数据.csv');
      await file.writeAsString(csvContent, encoding: utf8);
      
      // 分享文件
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.familyTree.name} 族谱数据',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV文件导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _generateCSVContent() {
    final buffer = StringBuffer();
    
    // 易读格式CSV头部
    buffer.writeln('姓名,性别,世代,排行,出生日期,父亲姓名,母亲姓名,配偶姓名,备注');
    
    // 按世代排序成员
    final sortedMembers = List<Member>.from(widget.members);
    sortedMembers.sort((a, b) => a.generation.compareTo(b.generation));
    
    // 成员数据 - 只保留易读格式
    for (final member in sortedMembers) {
      final spouse = _findSpouse(member);
      final father = _findFather(member);
      final mother = _findMother(member);
      
      final row = [
        member.name,
        _formatGender(member.gender),
        '第${member.generation}代',
        _formatRanking(member.ranking, member.gender),
        _formatBirthday(member.birthday),
        father?.name ?? '',
        mother?.name ?? '',
        spouse?.name ?? '',
        member.notes ?? '',
      ].join(',');
      
      buffer.writeln(row);
    }
    
    return buffer.toString();
  }

  Member? _findSpouse(Member member) {
    for (final relationship in widget.relationships) {
      if (relationship.type == RelationshipType.spouse) {
        if (relationship.parentId == member.id) {
          return widget.members.firstWhere(
            (m) => m.id == relationship.childId,
            orElse: () => member,
          );
        } else if (relationship.childId == member.id) {
          return widget.members.firstWhere(
            (m) => m.id == relationship.parentId,
            orElse: () => member,
          );
        }
      }
    }
    return null;
  }

  Member? _findFather(Member member) {
    for (final relationship in widget.relationships) {
      if (relationship.type == RelationshipType.parentChild && 
          relationship.childId == member.id) {
        final parent = widget.members.firstWhere(
          (m) => m.id == relationship.parentId,
          orElse: () => member,
        );
        // 只返回男性父亲
        if (parent.gender == Gender.male) {
          return parent;
        }
      }
    }
    return null;
  }

  Member? _findMother(Member member) {
    for (final relationship in widget.relationships) {
      if (relationship.type == RelationshipType.parentChild && 
          relationship.childId == member.id) {
        final parent = widget.members.firstWhere(
          (m) => m.id == relationship.parentId,
          orElse: () => member,
        );
        // 只返回女性母亲
        if (parent.gender == Gender.female) {
          return parent;
        }
      }
    }
    return null;
  }

  // 格式化性别 - 与桌面应用保持一致
  String _formatGender(Gender gender) {
    switch (gender) {
      case Gender.male:
        return '男';
      case Gender.female:
        return '女';
      case Gender.other:
        return '未知';
    }
  }

  // 格式化排行 - 与桌面应用保持一致
  String _formatRanking(int ranking, Gender gender) {
    if (ranking <= 0) {
      return '未知';
    } else if (ranking == 1) {
      return gender == Gender.female ? '长女' : '长子';
    } else if (ranking == 2) {
      return gender == Gender.female ? '次女' : '次子';
    } else if (ranking == 3) {
      return gender == Gender.female ? '三女' : '三子';
    } else if (ranking == 4) {
      return gender == Gender.female ? '四女' : '四子';
    } else if (ranking == 5) {
      return gender == Gender.female ? '五女' : '五子';
    } else {
      return '第${ranking}个';
    }
  }

  // 格式化出生日期 - 与桌面应用保持一致
  String _formatBirthday(DateTime? birthday) {
    if (birthday == null) return '';
    return '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _exportTreeImage() async {
    if (_isExporting) return;
    
    setState(() {
      _isExporting = true;
    });

    try {
      print('开始导出族谱图...');

      // 使用与族谱图页面相同的导出逻辑
      final image = await _renderFamilyTreeImage();

      if (image == null) {
        throw Exception('图片生成失败');
      }

      print('图片生成成功，图像大小: ${image.length} 字节');

      // 直接保存到相册
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.familyTree.name}_族谱图_$timestamp.png';
      
      // 先保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(image);
      
      print('临时文件保存成功: ${tempFile.path}');
      
      // 只保存到相册，让Gal插件直接触发系统权限对话框
      await Gal.putImage(tempFile.path);
      print('图片已保存到相册');
      
      // 删除临时文件
      await tempFile.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('族谱图已保存到相册: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('导出失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于应用'),
        content: const Text(
          '族谱制作 v1.0.0\n\n'
          '一个专为创建、编辑和导出族谱数据而设计的移动应用，'
          '让家族历史传承更加便捷。\n\n'
          '功能特点：\n'
          '• 创建和管理族谱\n'
          '• 添加和编辑家族成员\n'
          '• 可视化族谱图\n'
          '• 数据导出和备份',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '族谱制作应用使用指南\n',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                '1. 创建族谱\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• 点击主页面右上角的"+"按钮\n'
                '• 输入族谱名称和描述\n'
                '• 点击"保存"创建新族谱\n\n',
              ),
              const Text(
                '2. 添加家族成员\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• 进入族谱详情页面\n'
                '• 点击右上角的"+"按钮\n'
                '• 填写成员信息：姓名、性别、出生日期等\n'
                '• 设置成员关系（父母、配偶、子女）\n'
                '• 点击"保存"添加成员\n\n',
              ),
              const Text(
                '3. 查看族谱图\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• 在族谱详情页面切换到"族谱图"标签\n'
                '• 可以缩放和拖拽查看完整族谱\n'
                '• 点击成员节点查看详细信息\n'
                '• 不同颜色代表不同性别：蓝色(男)、红色(女)、灰色(其他)\n\n',
              ),
              const Text(
                '4. 编辑成员信息\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• 在成员列表中点击成员卡片\n'
                '• 进入成员详情页面\n'
                '• 点击右上角的编辑按钮\n'
                '• 修改信息后点击"保存"\n\n',
              ),
              const Text(
                '5. 导出数据\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• 在设置页面可以导出CSV格式的数据文件\n'
                '• 可以导出族谱图为图片文件\n'
                '• 支持分享到其他应用\n\n',
              ),
              const Text(
                '6. 颜色说明\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• 男性成员：蓝色标识\n'
                '• 女性成员：红色标识\n'
                '• 其他性别：灰色标识\n'
                '• 父子关系：红色连接线\n'
                '• 配偶关系：粉色连接线\n',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联系我们'),
        content: const Text(
          '如果您有任何问题或建议，请通过以下方式联系我们：\n\n'
          '邮箱：einstein995085987@gmail.com\n\n'
          '我们会在24小时内回复您的邮件。',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 复制邮箱到剪贴板
              Clipboard.setData(const ClipboardData(text: 'einstein995085987@gmail.com'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('邮箱地址已复制到剪贴板')),
              );
            },
            child: const Text('复制邮箱'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('功能开发中'),
        content: Text('$feature 正在开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 直接绘制族谱图到图片
  Future<Uint8List?> _renderFamilyTreeImage() async {
    try {
      // 计算布局
      final layout = _calculateTreeLayout();
      
      // 调试信息
      print('开始直接绘制族谱图...');
      print('画布大小: ${layout['width']} x ${layout['height']}');
      print('成员位置数量: ${(layout['positions'] as Map).length}');
      
      // 创建图片画布
      final imageSize = Size(layout['width'], layout['height']);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 绘制白色背景
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, imageSize.width, imageSize.height), backgroundPaint);
      
      // 绘制灰色背景
      final greyPaint = Paint()..color = Colors.grey[100]!;
      canvas.drawRect(Rect.fromLTWH(0, 0, imageSize.width, imageSize.height), greyPaint);
      
      // 绘制关系线
      _drawRelationshipsOnCanvas(canvas, layout);
      
      // 绘制世代标签
      _drawGenerationLabelsOnCanvas(canvas, layout);
      
      // 绘制成员节点
      _drawMemberNodesOnCanvas(canvas, layout);
      
      // 完成绘制
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        imageSize.width.toInt(), // 使用1倍分辨率
        imageSize.height.toInt(), // 使用1倍分辨率
      );
      
      // 转换为字节数组
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      print('图片绘制完成，字节数: ${byteData?.lengthInBytes}');
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('绘制图片失败: $e');
      return null;
    }
  }

  // 使用与族谱图显示相同的复杂布局算法
  Map<String, dynamic> _calculateTreeLayout() {
    if (widget.members.isEmpty) {
      return {
        'positions': <Member, Offset>{},
        'children': <Member, List<Member>>{},
        'spouses': <Member, List<Member>>{},
        'width': 400.0,
        'height': 400.0,
      };
    }

    // 构建关系图
    final Map<Member, List<Member>> children = {};
    final Map<Member, List<Member>> spouses = {};
    final Map<String, Member> memberMap = {};

    // 创建成员映射
    for (final member in widget.members) {
      memberMap[member.id] = member;
      children[member] = [];
      spouses[member] = [];
    }

    // 构建关系
    for (final relationship in widget.relationships) {
      final member1 = memberMap[relationship.parentId];
      final member2 = memberMap[relationship.childId];
      
      if (member1 != null && member2 != null) {
        if (relationship.type == RelationshipType.parentChild) {
          children[member1]!.add(member2);
        } else if (relationship.type == RelationshipType.spouse) {
          spouses[member1]!.add(member2);
          spouses[member2]!.add(member1);
        }
      }
    }

    // 使用与族谱图显示相同的递归布局算法
    final positions = <Member, Offset>{};
    final nodeSpacing = 60.0; // 节点间距 (水平间距60像素)
    final levelHeight = 120.0; // 世代间距 (垂直间距120像素)
    final margin = 50.0; // 边距
    
    // 世代标准化：找到最小世代值，用于位置计算偏移
    final minGeneration = widget.members.map((m) => m.generation).reduce((a, b) => a < b ? a : b);
    final generationOffset = minGeneration;
    
    print('导出世代标准化: 最小世代=$minGeneration, 位置偏移量=$generationOffset');
    
    // 找到根节点（没有父亲的成员）
    final roots = _findRoots(widget.members, children);
    
    // 计算每个子树的宽度
    final subtreeSizes = <Member, double>{};
    for (final root in roots) {
      _calculateSubtreeWidth(root, widget.members, subtreeSizes, nodeSpacing);
    }
    
    // 处理所有成员，确保没有遗漏
    final processedMembers = <Member>{};
    
    // 放置根节点及其子树
    double currentX = margin;
    for (final root in roots) {
      final rootWidth = subtreeSizes[root] ?? nodeSpacing;
      final rootX = currentX + rootWidth / 2;
      // 使用标准化的世代值计算位置：减去偏移量，让最年长的成员从顶部开始
      final normalizedGeneration = root.generation - generationOffset;
      _placeNode(root, Offset(rootX, margin + normalizedGeneration * levelHeight), 
                widget.members, subtreeSizes, positions, nodeSpacing, levelHeight, processedMembers, generationOffset, margin);
      currentX += rootWidth + nodeSpacing * 2;
    }
    
    // 处理没有父子关系的孤立成员
    final unprocessedMembers = widget.members.where((member) => !processedMembers.contains(member)).toList();
    
    for (final member in unprocessedMembers) {
      final memberX = currentX + nodeSpacing / 2;
      // 使用标准化的世代值计算位置：减去偏移量
      final normalizedGeneration = member.generation - generationOffset;
      final memberY = margin + normalizedGeneration * levelHeight;
      positions[member] = Offset(memberX, memberY);
      processedMembers.add(member);
      currentX += nodeSpacing * 2;
    }

    // 计算画布大小
    double maxX = 0;
    double maxY = 0;
    
    for (final position in positions.values) {
      maxX = math.max(maxX, position.dx + 100);
      maxY = math.max(maxY, position.dy + 100);
    }
    
    maxX = math.max(maxX, 800.0);
    maxY = math.max(maxY, 600.0);
    maxX += 100;
    maxY += 100;

    return {
      'positions': positions,
      'children': children,
      'spouses': spouses,
      'width': maxX,
      'height': maxY,
    };
  }

  // 找到根节点（没有父亲的成员）
  List<Member> _findRoots(List<Member> members, Map<Member, List<Member>> children) {
    final memberSet = members.toSet();
    final childrenOfFathers = <Member>{};
    
    for (final member in members) {
      if (member.gender == Gender.male) {
        final childList = children[member] ?? [];
        childrenOfFathers.addAll(childList);
      }
    }
    
    final roots = memberSet.difference(childrenOfFathers).toList();
    roots.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return roots;
  }
  
  // 计算子树宽度（与族谱图显示相同的算法）
  void _calculateSubtreeWidth(Member member, List<Member> members, 
                             Map<Member, double> subtreeSizes, double nodeSpacing) {
    final childList = _getChildren(member, members);
    
    if (childList.isEmpty) {
      subtreeSizes[member] = nodeSpacing;
      return;
    }
    
    // 递归计算所有子节点的宽度
    for (final child in childList) {
      _calculateSubtreeWidth(child, members, subtreeSizes, nodeSpacing);
    }
    
    // 计算总宽度：子节点宽度 + 间距
    final totalChildrenWidth = childList.fold(0.0, (sum, child) => sum + (subtreeSizes[child] ?? 0));
    final totalSpacing = (childList.length - 1) * nodeSpacing;
    subtreeSizes[member] = math.max(totalChildrenWidth + totalSpacing, nodeSpacing);
  }
  
  // 放置节点（与族谱图显示相同的算法）
  void _placeNode(Member member, Offset position, List<Member> members,
                 Map<Member, double> subtreeSizes, Map<Member, Offset> positions,
                 double nodeSpacing, double levelHeight, Set<Member> processedMembers, [int generationOffset = 0, double margin = 50.0]) {
    positions[member] = position;
    processedMembers.add(member);
    
    final childList = _getChildren(member, members);
    if (childList.isEmpty) return;
    
    final fullBlockWidth = subtreeSizes[member]!;
    double currentX = position.dx - (fullBlockWidth / 2);
    
    for (final child in childList) {
      final childSubtreeWidth = subtreeSizes[child] ?? nodeSpacing;
      final childX = currentX + (childSubtreeWidth / 2);
      // 使用标准化的世代值计算子节点位置
      final normalizedChildGeneration = child.generation - generationOffset;
      final childY = margin + normalizedChildGeneration * levelHeight;
      
      _placeNode(child, Offset(childX, childY), members, subtreeSizes, 
                positions, nodeSpacing, levelHeight, processedMembers, generationOffset, margin);
      currentX += childSubtreeWidth + nodeSpacing;
    }
  }
  
  // 获取子节点
  List<Member> _getChildren(Member parent, List<Member> members) {
    if (parent.gender != Gender.male) return [];
    
    final children = <Member>[];
    for (final relationship in widget.relationships) {
      if (relationship.type == RelationshipType.parentChild && 
          relationship.parentId == parent.id) {
        final child = members.firstWhere((m) => m.id == relationship.childId, 
                                        orElse: () => throw StateError('Child not found'));
        children.add(child);
      }
    }
    
    children.sort((a, b) => a.ranking.compareTo(b.ranking));
    return children;
  }

  // 在画布上绘制关系线
  void _drawRelationshipsOnCanvas(Canvas canvas, Map<String, dynamic> layout) {
    final positions = layout['positions'] as Map<Member, Offset>;
    final children = layout['children'] as Map<Member, List<Member>>;
    final spouses = layout['spouses'] as Map<Member, List<Member>>;
    
    // 绘制父子关系
    final parentChildPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final entry in children.entries) {
      final parent = entry.key;
      final childrenList = entry.value;
      
      if (childrenList.isNotEmpty && positions.containsKey(parent)) {
        final parentPos = positions[parent]!;
        
        for (final child in childrenList) {
          if (positions.containsKey(child)) {
            final childPos = positions[child]!;
            _drawParentChildLineOnCanvas(canvas, parentChildPaint, parentPos, childPos);
          }
        }
      }
    }

    // 绘制配偶关系
    final spousePaint = Paint()
      ..color = Colors.pink[400]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final entry in spouses.entries) {
      final member = entry.key;
      final spousesList = entry.value;
      
      if (spousesList.isNotEmpty && positions.containsKey(member)) {
        final memberPos = positions[member]!;
        
        for (final spouse in spousesList) {
          if (positions.containsKey(spouse)) {
            final spousePos = positions[spouse]!;
            _drawSpouseLineOnCanvas(canvas, spousePaint, memberPos, spousePos);
          }
        }
      }
    }
  }

  // 在画布上绘制父子关系线
  void _drawParentChildLineOnCanvas(Canvas canvas, Paint paint, Offset parentPos, Offset childPos) {
    final parentBottom = Offset(parentPos.dx, parentPos.dy + 30);
    final childTop = Offset(childPos.dx, childPos.dy - 30);
    
    // 计算中间点：父节点底部和子节点顶部之间的中点
    final midPointY = parentBottom.dy + (childTop.dy - parentBottom.dy) / 2;
    
    final path = Path();
    path.moveTo(parentBottom.dx, parentBottom.dy);
    path.lineTo(parentBottom.dx, midPointY);
    path.lineTo(childTop.dx, midPointY);
    path.lineTo(childTop.dx, childTop.dy);
    
    canvas.drawPath(path, paint);
  }

  // 在画布上绘制配偶关系线
  void _drawSpouseLineOnCanvas(Canvas canvas, Paint paint, Offset pos1, Offset pos2) {
    final startPoint = Offset(pos1.dx + 30, pos1.dy);
    final endPoint = Offset(pos2.dx - 30, pos2.dy);
    
    canvas.drawLine(startPoint, endPoint, paint);
  }

  // 在画布上绘制成员节点
  void _drawGenerationLabelsOnCanvas(Canvas canvas, Map<String, dynamic> layout) {
    // 获取所有世代
    final generations = <int>{};
    for (final member in widget.members) {
      generations.add(member.generation);
    }
    
    final sortedGenerations = generations.toList()..sort();
    final positions = layout['positions'] as Map<Member, Offset>;
    
    for (final generation in sortedGenerations) {
      // 找到该世代的第一个成员位置作为标签位置
      final membersInGeneration = widget.members
          .where((m) => m.generation == generation)
          .where((m) => positions.containsKey(m))
          .toList();
      
      if (membersInGeneration.isEmpty) continue;
      
      // 使用该世代第一个成员的位置
      final firstMember = membersInGeneration.first;
      final position = positions[firstMember]!;
      
      // 绘制世代标签背景
      final labelRect = Rect.fromLTWH(
        10, // 左侧边距
        position.dy - 20, // 在节点上方
        60, // 标签宽度
        20, // 标签高度
      );
      
      final labelPaint = Paint()
        ..color = Colors.black.withOpacity(0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(12)),
        labelPaint
      );
      
      // 绘制标签边框
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(12)),
        borderPaint
      );
      
      // 绘制标签文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: '第${generation}代',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final textOffset = Offset(
        labelRect.left + (labelRect.width - textPainter.width) / 2,
        labelRect.top + (labelRect.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawMemberNodesOnCanvas(Canvas canvas, Map<String, dynamic> layout) {
    final positions = layout['positions'] as Map<Member, Offset>;
    
    for (final entry in positions.entries) {
      final member = entry.key;
      final position = entry.value;
      
      _drawMemberNodeOnCanvas(canvas, member, position);
    }
  }

  // 在画布上绘制单个成员节点
  void _drawMemberNodeOnCanvas(Canvas canvas, Member member, Offset position) {
    // 绘制阴影效果
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    
    final shadowRect = Rect.fromLTWH(
      position.dx - 30, 
      position.dy - 30 + 1, // 与屏幕显示一致 (0, 1)
      60, 
      60
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(8)),
      shadowPaint
    );
    
    // 绘制白色背景
    final backgroundPaint = Paint()..color = Colors.white;
    final backgroundRect = Rect.fromLTWH(
      position.dx - 30, 
      position.dy - 30, 
      60, 
      60
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      backgroundPaint
    );
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      borderPaint
    );
    
    // 绘制性别图标
    final iconPaint = Paint()..color = _getGenderColor(member.gender);
    
    // 绘制圆形背景 - 头像距离顶部1像素，整体上移5像素，再下移3像素
    canvas.drawCircle(
      Offset(position.dx, position.dy - 21), // 调整位置：-24 + 3 = -21，整体下移3像素
      7.5,
      iconPaint
    );
    
    // 绘制白色边框
    final iconBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
      Offset(position.dx, position.dy - 21), // 调整位置：-24 + 3 = -21，整体下移3像素
      7.5,
      iconBorderPaint
    );
    
    // 绘制Flutter图标
    _drawFlutterIconOnCanvas(canvas, Offset(position.dx, position.dy - 21), member.gender);
    
    // 绘制姓名 - 添加宽度限制和省略号处理
    final maxWidth = 50.0; // 限制文字最大宽度为50像素，确保在60x60节点框内
    final displayName = member.name.isNotEmpty ? member.name : '?';
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: displayName,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500, // 与屏幕显示一致
          fontSize: 28,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(maxWidth: maxWidth);
    
    // 如果文字超出宽度，添加省略号
    String finalText = displayName;
    if (textPainter.didExceedMaxLines) {
      // 逐步减少字符直到适合宽度
      for (int i = displayName.length - 1; i > 0; i--) {
        final truncatedText = displayName.substring(0, i) + '...';
        final testTextPainter = TextPainter(
          text: TextSpan(
            text: truncatedText,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 28,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        testTextPainter.layout();
        if (testTextPainter.width <= maxWidth) {
          finalText = truncatedText;
          break;
        }
      }
      
      // 重新创建TextPainter使用截断后的文字
      textPainter.text = TextSpan(
        text: finalText,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 28,
        ),
      );
      textPainter.layout();
    }
    
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - 11.5, // 头像底部 + 2像素间距，整体下移3像素：-14.5 + 3 = -11.5
      ),
    );
  }

  // 在Canvas上绘制Flutter图标
  void _drawFlutterIconOnCanvas(Canvas canvas, Offset center, Gender gender) {
    final iconData = _getGenderIcon(gender);
    final iconSize = 9.0;
    
    // 创建TextPainter来绘制图标
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: iconData.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // 计算图标位置（居中）
    final iconOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    
    // 绘制图标
    textPainter.paint(canvas, iconOffset);
  }

  // 获取性别图标
  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Icons.person;
      case Gender.female:
        return Icons.person;
      case Gender.other:
        return Icons.person_outline;
    }
  }

  // 获取性别颜色
  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return const Color(0xFF1976D2); // 男性蓝色
      case Gender.female:
        return const Color(0xFFD32F2F); // 女性红色
      case Gender.other:
        return const Color(0xFF808080); // 其他灰色
    }
  }
}
