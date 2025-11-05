import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloud_sync_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _syncService = CloudSyncService();
  
  bool _isLoading = false;
  bool _isLoginMode = true; // true=登录, false=注册

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo和标题
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  _isLoginMode ? '登录账户' : '创建账户',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  '同步您的家族树数据到云端',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 登录表单
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 邮箱输入
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: '邮箱',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入邮箱';
                          }
                          if (!value.contains('@')) {
                            return '请输入有效的邮箱地址';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 密码输入
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                          if (value.length < 6) {
                            return '密码至少6位';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 登录/注册按钮
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isLoginMode ? '登录' : '注册',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 切换登录/注册
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                          });
                        },
                        child: Text(
                          _isLoginMode ? '没有账户？立即注册' : '已有账户？立即登录',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
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
                      
                      const SizedBox(height: 20),
                      
                      // 匿名登录
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleAnonymousLogin,
                          icon: const Icon(Icons.person_outline),
                          label: const Text('匿名登录（快速开始）'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4CAF50),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 跳过登录
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          '跳过，稍后登录',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isLoginMode) {
        success = await _syncService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        ).timeout(
          const Duration(seconds: 60), // 增加超时时间，因为需要重试
          onTimeout: () {
            throw Exception('网络连接超时，请检查网络设置或稍后重试');
          },
        );
      } else {
        success = await _syncService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        ).timeout(
          const Duration(seconds: 60), // 增加超时时间，因为需要重试
          onTimeout: () {
            throw Exception('网络连接超时，请检查网络设置或稍后重试');
          },
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLoginMode ? '登录成功！' : '注册成功！'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLoginMode ? '登录失败，请检查邮箱和密码' : '注册失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = '网络连接失败，请检查网络设置后重试';
            break;
          case 'wrong-password':
            errorMessage = '密码错误，请重新输入';
            break;
          case 'user-not-found':
            errorMessage = '用户不存在，请先注册';
            break;
          case 'user-disabled':
            errorMessage = '账户已被禁用，请联系客服';
            break;
          case 'too-many-requests':
            errorMessage = '请求过于频繁，请稍后再试';
            break;
          case 'invalid-email':
            errorMessage = '邮箱格式不正确';
            break;
          case 'email-already-in-use':
            errorMessage = '该邮箱已被注册，请直接登录';
            break;
          case 'weak-password':
            errorMessage = '密码过于简单，请设置更复杂的密码';
            break;
          case 'operation-not-allowed':
            errorMessage = '该登录方式未启用，请联系管理员';
            break;
          default:
            errorMessage = '${_isLoginMode ? '登录' : '注册'}失败: ${e.message ?? e.code}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: e.code == 'network-request-failed'
                ? SnackBarAction(
                    label: '重试',
                    textColor: Colors.white,
                    onPressed: () => _handleSubmit(),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('timeout') || errorMessage.contains('网络')) {
          errorMessage = '网络连接超时，请检查网络设置或稍后重试';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () => _handleSubmit(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAnonymousLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _syncService.signInAnonymously().timeout(
        const Duration(seconds: 60), // 增加超时时间，因为需要重试
        onTimeout: () {
          throw Exception('网络连接超时，请检查网络设置或稍后重试');
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('匿名登录成功！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登录失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = '网络连接失败，请检查网络设置后重试';
            break;
          case 'operation-not-allowed':
            errorMessage = '匿名登录未启用，请联系管理员';
            break;
          default:
            errorMessage = '登录失败: ${e.message ?? e.code}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: e.code == 'network-request-failed'
                ? SnackBarAction(
                    label: '重试',
                    textColor: Colors.white,
                    onPressed: () => _handleAnonymousLogin(),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('timeout') || errorMessage.contains('网络')) {
          errorMessage = '网络连接超时，请检查网络设置或稍后重试';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () => _handleAnonymousLogin(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

