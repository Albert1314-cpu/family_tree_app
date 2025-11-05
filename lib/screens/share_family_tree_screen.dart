import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/cloud_sync_service.dart';
import '../models/family_tree.dart';
import '../providers/family_tree_provider.dart';
import 'home_screen.dart';

class ShareFamilyTreeScreen extends StatefulWidget {
  final FamilyTree familyTree;

  const ShareFamilyTreeScreen({
    Key? key,
    required this.familyTree,
  }) : super(key: key);

  @override
  State<ShareFamilyTreeScreen> createState() => _ShareFamilyTreeScreenState();
}

class _ShareFamilyTreeScreenState extends State<ShareFamilyTreeScreen> {
  final _syncService = CloudSyncService();
  final _shareCodeController = TextEditingController();
  
  String? _generatedShareCode;
  bool _isGenerating = false;
  bool _isAccessing = false;

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分享家族树'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分享说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '生成分享码后，其他用户可以通过分享码查看您的家族树',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 当前家族树信息
            Text(
              '当前家族树',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.account_tree,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.familyTree.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.familyTree.notes != null && widget.familyTree.notes!.isNotEmpty)
                          Text(
                            widget.familyTree.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 生成分享码
            Text(
              '生成分享码',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            if (_generatedShareCode != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '分享码已生成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _generatedShareCode!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _generatedShareCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('分享码已复制到剪贴板'),
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, color: Colors.white),
                          label: const Text(
                            '复制分享码',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '有效期：30天',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateShareCode,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.share),
                  label: Text(_isGenerating ? '生成中...' : '生成分享码'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 40),
            
            // 分割线
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '或',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // 输入分享码访问
            Text(
              '访问他人分享的家族树',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _shareCodeController,
              decoration: InputDecoration(
                labelText: '输入分享码',
                hintText: '请输入6位分享码',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isAccessing ? null : _accessSharedTree,
                icon: _isAccessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_isAccessing ? '访问中...' : '访问家族树'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateShareCode() async {
    if (!_syncService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先登录账户'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final shareCode = await _syncService.shareFamilyTree(widget.familyTree.id);

      if (shareCode.isNotEmpty && mounted) {
        setState(() {
          _generatedShareCode = shareCode;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分享码生成成功！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('生成分享码失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _accessSharedTree() async {
    final shareCode = _shareCodeController.text.trim();
    
    if (shareCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入分享码'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_syncService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先登录账户'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAccessing = true;
    });

    try {
      final sharedTree = await _syncService.accessSharedTree(shareCode);

      if (sharedTree != null && mounted) {
        // 如果是协作家族树，获取 ownerId 并保存到 Provider
        if (sharedTree.isCollaborative) {
          final ownerId = await _syncService.getOwnerIdByShareCode(shareCode);
          if (ownerId != null) {
            context.read<FamilyTreeProvider>().setCollaborativeTreeOwner(
              sharedTree.id,
              ownerId,
            );
            print('已保存协作家族树 ownerId: $ownerId for treeId: ${sharedTree.id}');
          }
        }
        
        // 将访问的家族树保存到本地数据库，这样主页才能显示
        await context.read<FamilyTreeProvider>().addCollaborativeFamilyTree(sharedTree);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('访问成功！已加入协作家族树：${sharedTree.name}'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 关闭所有页面并返回到主页
        // 清除整个导航栈，只保留主页
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
            (route) => false, // 清除所有页面，包括主页（MaterialApp会重建主页）
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // 提供更友好的错误信息
        if (errorMessage.contains('过期')) {
          errorMessage = '分享码已过期（有效期30天），请联系创建者重新生成分享码';
        } else if (errorMessage.contains('不存在')) {
          errorMessage = '分享码不存在，请检查分享码是否正确';
        } else if (errorMessage.contains('permission-denied')) {
          errorMessage = '权限不足，请确保已在 Firebase Console 配置正确的安全规则（参考 FIRESTORE_RULES_SETUP.md）';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccessing = false;
        });
      }
    }
  }
}

