import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/family_tree.dart';
import '../models/member.dart';

// 性别转换辅助方法
String _genderToString(Gender gender) {
  switch (gender) {
    case Gender.male:
      return 'male';
    case Gender.female:
      return 'female';
    case Gender.other:
      return 'other';
  }
}

Gender _parseGender(String? genderString) {
  switch (genderString) {
    case 'male':
      return Gender.male;
    case 'female':
      return Gender.female;
    default:
      return Gender.other;
  }
}

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  // 延迟初始化 Firebase 服务，避免在 Firebase 未配置时崩溃
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  FirebaseStorage? _storage;
  
  bool _isFirebaseAvailable = false;

  // 检查 Firebase 是否可用
  bool get isFirebaseAvailable {
    if (!_isFirebaseAvailable) {
      try {
        _isFirebaseAvailable = Firebase.apps.isNotEmpty;
        if (_isFirebaseAvailable) {
          _firestore ??= FirebaseFirestore.instance;
          _auth ??= FirebaseAuth.instance;
          _storage ??= FirebaseStorage.instance;
        }
      } catch (e) {
        _isFirebaseAvailable = false;
        print('Firebase 不可用: $e');
      }
    }
    return _isFirebaseAvailable;
  }

  // 获取当前用户ID
  String? get currentUserId => isFirebaseAvailable ? _auth?.currentUser?.uid : null;
  bool get isLoggedIn => isFirebaseAvailable && _auth?.currentUser != null;

  // 用户认证 - 手机号登录
  Future<bool> signInWithPhone(String phoneNumber, String verificationCode) async {
    if (!isFirebaseAvailable) {
      print('Firebase 未配置，无法使用手机号登录');
      return false;
    }
    try {
      // 这里需要实现完整的手机验证流程
      // 简化版本，实际使用时需要完整实现
      return true;
    } catch (e) {
      print('登录失败: $e');
      return false;
    }
  }

  // 匿名登录（快速开始，带重试机制）
  Future<bool> signInAnonymously() async {
    if (!isFirebaseAvailable) {
      print('Firebase 未配置，跳过匿名登录');
      return false;
    }
    
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        await _auth!.signInAnonymously();
        return true;
      } on FirebaseAuthException catch (e) {
        // 网络错误可以重试，其他认证错误直接抛出
        if (e.code == 'network-request-failed') {
          retryCount++;
          print('匿名登录失败 (尝试 $retryCount/$maxRetries): ${e.code} - ${e.message}');
          
          if (retryCount >= maxRetries) {
            // 达到最大重试次数，抛出详细错误
            throw FirebaseAuthException(
              code: e.code,
              message: '网络连接失败，请检查网络设置后重试。如果问题持续，请参考 NETWORK_TROUBLESHOOTING.md',
            );
          }
          
          // 等待后重试（指数退避）
          await Future.delayed(Duration(seconds: retryCount * 2)); // 增加等待时间
        } else {
          // 其他认证错误（如 operation-not-allowed）直接抛出
          print('匿名登录失败: ${e.code} - ${e.message}');
          rethrow;
        }
      } catch (e) {
        retryCount++;
        print('匿名登录失败 (尝试 $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          // 达到最大重试次数，抛出错误
          throw Exception('网络连接失败，请检查网络设置后重试');
        }
        
        // 等待后重试（指数退避）
        await Future.delayed(Duration(seconds: retryCount * 2)); // 增加等待时间
      }
    }
    return false;
  }

  // 邮箱登录（带重试机制）
  Future<bool> signInWithEmail(String email, String password) async {
    if (!isFirebaseAvailable) {
      print('Firebase 未配置，无法使用邮箱登录');
      return false;
    }
    
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        await _auth!.signInWithEmailAndPassword(email: email, password: password);
        return true;
      } on FirebaseAuthException catch (e) {
        // 网络错误可以重试，其他认证错误直接抛出
        if (e.code == 'network-request-failed') {
          retryCount++;
          print('邮箱登录失败 (尝试 $retryCount/$maxRetries): ${e.code} - ${e.message}');
          
          if (retryCount >= maxRetries) {
            // 达到最大重试次数，抛出详细错误
            throw FirebaseAuthException(
              code: e.code,
              message: '网络连接失败，请检查网络设置后重试。如果问题持续，请参考 NETWORK_TROUBLESHOOTING.md',
            );
          }
          
          // 等待后重试（指数退避）
          await Future.delayed(Duration(seconds: retryCount * 2)); // 增加等待时间
        } else {
          // 其他认证错误（如 wrong-password, user-not-found）直接抛出
          print('邮箱登录失败: ${e.code} - ${e.message}');
          rethrow;
        }
      } catch (e) {
        retryCount++;
        print('邮箱登录失败 (尝试 $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          // 达到最大重试次数，抛出错误
          throw Exception('网络连接失败，请检查网络设置后重试');
        }
        
        // 等待后重试（指数退避）
        await Future.delayed(Duration(seconds: retryCount * 2)); // 增加等待时间
      }
    }
    return false;
  }

  // 邮箱注册（带重试机制）
  Future<bool> signUpWithEmail(String email, String password) async {
    if (!isFirebaseAvailable) {
      print('Firebase 未配置，无法使用邮箱注册');
      return false;
    }
    
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        await _auth!.createUserWithEmailAndPassword(email: email, password: password);
        return true;
      } on FirebaseAuthException catch (e) {
        // 网络错误可以重试，其他认证错误直接抛出
        if (e.code == 'network-request-failed') {
          retryCount++;
          print('注册失败 (尝试 $retryCount/$maxRetries): ${e.code} - ${e.message}');
          
          if (retryCount >= maxRetries) {
            // 达到最大重试次数，抛出详细错误
            throw FirebaseAuthException(
              code: e.code,
              message: '网络连接失败，请检查网络设置后重试。如果问题持续，请参考 NETWORK_TROUBLESHOOTING.md',
            );
          }
          
          // 等待后重试（指数退避）
          await Future.delayed(Duration(seconds: retryCount * 2)); // 增加等待时间
        } else {
          // 其他认证错误（如 email-already-in-use, weak-password）直接抛出
          print('注册失败: ${e.code} - ${e.message}');
          rethrow;
        }
      } catch (e) {
        retryCount++;
        print('注册失败 (尝试 $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          // 达到最大重试次数，抛出错误
          throw Exception('网络连接失败，请检查网络设置后重试');
        }
        
        // 等待后重试（指数退避）
        await Future.delayed(Duration(seconds: retryCount * 2)); // 增加等待时间
      }
    }
    return false;
  }

  // 登出
  Future<void> signOut() async {
    if (!isFirebaseAvailable) {
      return;
    }
    await _auth!.signOut();
  }

  // 上传家族树到云端
  Future<bool> uploadFamilyTree(FamilyTree familyTree) async {
    if (!isFirebaseAvailable || !isLoggedIn) return false;

    try {
      await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTree.id)
          .set({
        'id': familyTree.id,
        'name': familyTree.name,
        'surname': familyTree.surname,
        'notes': familyTree.notes,
        'createdAt': familyTree.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isCollaborative': familyTree.isCollaborative,
      });

      return true;
    } catch (e) {
      print('上传家族树失败: $e');
      return false;
    }
  }

  // 上传家族成员
  Future<bool> uploadMember(String familyTreeId, Member member) async {
    if (!isFirebaseAvailable || !isLoggedIn) return false;

    try {
      // 如果有照片，先上传照片
      String? photoUrl;
      if (member.photoPath != null && member.photoPath!.isNotEmpty) {
        photoUrl = await uploadPhoto(familyTreeId, member.id, member.photoPath!);
      }

      await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .collection('members')
          .doc(member.id)
          .set({
        'id': member.id,
        'name': member.name,
        'gender': _genderToString(member.gender),
        'birthday': member.birthday?.toIso8601String(),
        'deathday': member.deathday?.toIso8601String(),
        'birthPlace': member.birthPlace,
        'occupation': member.occupation,
        'notes': member.notes,
        'photoUrl': photoUrl,
        'photoPath': member.photoPath,
        'generation': member.generation,
        'ranking': member.ranking,
        'spouseName': member.spouseName,
        'familyTreeId': member.familyTreeId,
        'createdAt': member.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('上传成员失败: $e');
      return false;
    }
  }

  // 上传照片到云存储
  Future<String?> uploadPhoto(String familyTreeId, String memberId, String localPath) async {
    if (!isFirebaseAvailable || !isLoggedIn) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final ref = _storage!
          .ref()
          .child('users')
          .child(currentUserId!)
          .child('family_trees')
          .child(familyTreeId)
          .child('photos')
          .child('$memberId.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('上传照片失败: $e');
      return null;
    }
  }

  // 下载所有家族树
  Future<List<FamilyTree>> downloadFamilyTrees() async {
    if (!isFirebaseAvailable || !isLoggedIn) return [];

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyTree(
          id: data['id'],
          name: data['name'],
          surname: data['surname'],
          notes: data['notes'],
          updatedAt: DateTime.parse(data['updatedAt']),
          isCollaborative: data['isCollaborative'] ?? false,
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();
    } catch (e) {
      print('下载家族树失败: $e');
      return [];
    }
  }

  // 下载家族成员
  Future<List<Member>> downloadMembers(String familyTreeId) async {
    if (!isFirebaseAvailable || !isLoggedIn) return [];

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .collection('members')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Member(
          id: data['id'],
          name: data['name'],
          gender: _parseGender(data['gender']),
          birthday: data['birthday'] != null ? DateTime.parse(data['birthday']) : null,
          deathday: data['deathday'] != null ? DateTime.parse(data['deathday']) : null,
          birthPlace: data['birthPlace'],
          occupation: data['occupation'],
          notes: data['notes'],
          photoPath: data['photoPath'],
          generation: data['generation'] ?? 0,
          ranking: data['ranking'] ?? 0,
          spouseName: data['spouseName'],
          familyTreeId: data['familyTreeId'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
      }).toList();
    } catch (e) {
      print('下载成员失败: $e');
      return [];
    }
  }

  // 实时监听家族树变化
  Stream<List<FamilyTree>> watchFamilyTrees() {
    if (!isLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('family_trees')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyTree(
          id: data['id'],
          name: data['name'],
          surname: data['surname'],
          notes: data['notes'],
          updatedAt: DateTime.parse(data['updatedAt']),
          isCollaborative: data['isCollaborative'] ?? false,
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();
    });
  }

  // 分享家族树给其他用户（支持协作模式）
  Future<String> shareFamilyTree(String familyTreeId, {bool enableCollaboration = true}) async {
    if (!isFirebaseAvailable || !isLoggedIn) return '';

    try {
      // 如果启用协作，先设置为协作模式
      if (enableCollaboration) {
        await enableCollaborationMode(familyTreeId);
      }
      
      // 创建分享链接
      final shareDoc = await _firestore!.collection('shared_trees').add({
        'ownerId': currentUserId,
        'familyTreeId': familyTreeId,
        'isCollaborative': enableCollaboration,
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      return shareDoc.id;
    } catch (e) {
      print('创建分享链接失败: $e');
      return '';
    }
  }

  // 通过分享码访问家族树（并加入协作）
  Future<FamilyTree?> accessSharedTree(String shareCode) async {
    if (!isFirebaseAvailable || !isLoggedIn) {
      throw Exception('请先登录账户');
    }

    try {
      final shareDoc = await _firestore!.collection('shared_trees').doc(shareCode).get();
      
      if (!shareDoc.exists) {
        throw Exception('分享码不存在，请检查分享码是否正确');
      }

      final data = shareDoc.data()!;
      
      // 检查分享码是否过期
      if (data['expiresAt'] != null) {
        final expiresAt = DateTime.parse(data['expiresAt']);
        if (DateTime.now().isAfter(expiresAt)) {
          throw Exception('分享码已过期（有效期30天），请联系创建者重新生成分享码');
        }
      }
      
      final ownerId = data['ownerId'];
      final familyTreeId = data['familyTreeId'];

      // 获取家族树信息
      final treeDoc = await _firestore!
          .collection('users')
          .doc(ownerId)
          .collection('family_trees')
          .doc(familyTreeId)
          .get();

      if (!treeDoc.exists) {
        throw Exception('家族树不存在，可能已被删除');
      }

      final treeData = treeDoc.data()!;
      
      // 如果是协作家族树，添加到协作者列表
      if (treeData['isCollaborative'] == true) {
        try {
          await _addCollaborator(familyTreeId, currentUserId!);
        } catch (e) {
          // 如果添加协作者失败（可能是权限问题），但不影响访问家族树
          print('添加协作者失败（可忽略）: $e');
        }
      }
      
      // 返回家族树信息，保存 ownerId 用于后续加载数据
      final familyTree = FamilyTree(
        id: treeData['id'],
        name: treeData['name'],
        surname: treeData['surname'],
        notes: treeData['notes'],
        updatedAt: DateTime.parse(treeData['updatedAt']),
        isCollaborative: treeData['isCollaborative'] ?? false,
        createdAt: DateTime.parse(treeData['createdAt']),
      );
      
      // 保存 ownerId 到本地存储（用于后续加载协作数据）
      // 可以通过 shareDoc 的 ownerId 来加载数据
      print('访问分享家族树成功: ${familyTree.name}, ownerId: $ownerId, treeId: $familyTreeId');
      
      return familyTree;
    } catch (e) {
      print('访问分享家族树失败: $e');
      rethrow; // 重新抛出异常，让调用者知道具体错误
    }
  }

  // 启用协作模式（将家族树转为协作树）
  Future<bool> enableCollaborationMode(String familyTreeId) async {
    if (!isFirebaseAvailable || !isLoggedIn) return false;

    try {
      // 先检查家族树是否存在
      final treeDoc = await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .get();
      
      if (!treeDoc.exists) {
        print('家族树不存在于云端，无法启用协作模式。请先上传家族树到云端。');
        return false;
      }
      
      // 更新家族树为协作模式
      await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .update({
        'isCollaborative': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 添加创建者为协作者
      await _addCollaborator(familyTreeId, currentUserId!);
      
      return true;
    } catch (e) {
      print('启用协作模式失败: $e');
      return false;
    }
  }

  // 添加协作者
  Future<bool> _addCollaborator(String familyTreeId, String userId) async {
    if (!isFirebaseAvailable) return false;
    
    try {
      await _firestore!
          .collection('collaborative_trees')
          .doc(familyTreeId)
          .collection('collaborators')
          .doc(userId)
          .set({
        'userId': userId,
        'joinedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('添加协作者失败: $e');
      return false;
    }
  }

  // 获取协作者列表
  Future<List<String>> getCollaborators(String familyTreeId) async {
    if (!isFirebaseAvailable || !isLoggedIn) return [];

    try {
      final snapshot = await _firestore!
          .collection('collaborative_trees')
          .doc(familyTreeId)
          .collection('collaborators')
          .get();

      return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
    } catch (e) {
      print('获取协作者列表失败: $e');
      return [];
    }
  }

  // 从云端加载协作家族树的成员（一次性加载）
  Future<List<Member>> loadCollaborativeMembers(String familyTreeId, String ownerId) async {
    if (!isFirebaseAvailable || !isLoggedIn) return [];

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(ownerId)
          .collection('family_trees')
          .doc(familyTreeId)
          .collection('members')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Member(
          id: data['id'],
          name: data['name'],
          gender: _parseGender(data['gender']),
          birthday: data['birthday'] != null ? DateTime.parse(data['birthday']) : null,
          deathday: data['deathday'] != null ? DateTime.parse(data['deathday']) : null,
          birthPlace: data['birthPlace'],
          occupation: data['occupation'],
          notes: data['notes'],
          photoPath: data['photoPath'],
          generation: data['generation'] ?? 0,
          ranking: data['ranking'] ?? 0,
          spouseName: data['spouseName'],
          familyTreeId: data['familyTreeId'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
      }).toList();
    } catch (e) {
      print('加载协作家族树成员失败: $e');
      return [];
    }
  }

  // 根据分享码获取 ownerId（用于加载协作数据）
  Future<String?> getOwnerIdByShareCode(String shareCode) async {
    if (!isFirebaseAvailable || !isLoggedIn) return null;

    try {
      final shareDoc = await _firestore!.collection('shared_trees').doc(shareCode).get();
      if (!shareDoc.exists) return null;
      return shareDoc.data()?['ownerId'] as String?;
    } catch (e) {
      print('获取 ownerId 失败: $e');
      return null;
    }
  }

  // 实时监听协作家族树的数据变化（成员变化）
  Stream<List<Member>> watchCollaborativeMembers(String familyTreeId, String ownerId) {
    if (!isFirebaseAvailable || !isLoggedIn) return Stream.value([]);

    return _firestore!
        .collection('users')
        .doc(ownerId)
        .collection('family_trees')
        .doc(familyTreeId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Member(
          id: data['id'],
          name: data['name'],
          gender: _parseGender(data['gender']),
          birthday: data['birthday'] != null ? DateTime.parse(data['birthday']) : null,
          deathday: data['deathday'] != null ? DateTime.parse(data['deathday']) : null,
          birthPlace: data['birthPlace'],
          occupation: data['occupation'],
          notes: data['notes'],
          photoPath: data['photoPath'],
          generation: data['generation'] ?? 0,
          ranking: data['ranking'] ?? 0,
          spouseName: data['spouseName'],
          familyTreeId: data['familyTreeId'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
      }).toList();
    });
  }

  // 上传成员到协作家族树（自动同步给其他用户）
  Future<bool> uploadMemberToCollaborativeTree(
    String familyTreeId,
    String ownerId,
    Member member,
  ) async {
    if (!isFirebaseAvailable || !isLoggedIn) return false;

    try {
      // 上传到原拥有者的家族树（其他用户通过监听可以看到）
      String? photoUrl;
      if (member.photoPath != null && member.photoPath!.isNotEmpty) {
        photoUrl = await uploadPhoto(familyTreeId, member.id, member.photoPath!);
      }

      await _firestore!
          .collection('users')
          .doc(ownerId)
          .collection('family_trees')
          .doc(familyTreeId)
          .collection('members')
          .doc(member.id)
          .set({
        'id': member.id,
        'name': member.name,
        'gender': _genderToString(member.gender),
        'birthday': member.birthday?.toIso8601String(),
        'deathday': member.deathday?.toIso8601String(),
        'birthPlace': member.birthPlace,
        'occupation': member.occupation,
        'notes': member.notes,
        'photoUrl': photoUrl,
        'photoPath': member.photoPath,
        'generation': member.generation,
        'ranking': member.ranking,
        'spouseName': member.spouseName,
        'familyTreeId': member.familyTreeId,
        'createdAt': member.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'addedBy': currentUserId, // 记录是谁添加的
      });

      return true;
    } catch (e) {
      print('上传成员到协作树失败: $e');
      return false;
    }
  }
  
  // 从协作家族树删除成员（自动同步给其他用户）
  Future<bool> deleteMemberFromCollaborativeTree(
    String familyTreeId,
    String ownerId,
    String memberId,
  ) async {
    if (!isFirebaseAvailable || !isLoggedIn) return false;

    try {
      await _firestore!
          .collection('users')
          .doc(ownerId)
          .collection('family_trees')
          .doc(familyTreeId)
          .collection('members')
          .doc(memberId)
          .delete();

      return true;
    } catch (e) {
      print('从协作树删除成员失败: $e');
      return false;
    }
  }

  // 删除云端家族树
  Future<bool> deleteFamilyTree(String familyTreeId) async {
    if (!isFirebaseAvailable || !isLoggedIn) return false;

    try {
      // 删除所有成员
      final membersSnapshot = await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .collection('members')
          .get();

      for (var doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // 删除家族树
      await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .delete();

      return true;
    } catch (e) {
      print('删除家族树失败: $e');
      return false;
    }
  }

  // 同步本地数据到云端
  Future<bool> syncToCloud(FamilyTree familyTree, List<Member> members) async {
    if (!isLoggedIn) return false;

    try {
      // 上传家族树
      await uploadFamilyTree(familyTree);

      // 上传所有成员
      for (var member in members) {
        await uploadMember(familyTree.id, member);
      }

      return true;
    } catch (e) {
      print('同步到云端失败: $e');
      return false;
    }
  }

  // 从云端同步到本地
  Future<Map<String, dynamic>?> syncFromCloud(String familyTreeId) async {
    if (!isFirebaseAvailable || !isLoggedIn) return null;

    try {
      // 下载家族树
      final treeDoc = await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('family_trees')
          .doc(familyTreeId)
          .get();

      if (!treeDoc.exists) return null;

      final treeData = treeDoc.data()!;
      final familyTree = FamilyTree(
        id: treeData['id'],
        name: treeData['name'],
        surname: treeData['surname'],
        notes: treeData['notes'],
        updatedAt: DateTime.parse(treeData['updatedAt']),
        isCollaborative: treeData['isCollaborative'] ?? false,
        createdAt: DateTime.parse(treeData['createdAt']),
      );

      // 下载成员
      final members = await downloadMembers(familyTreeId);

      return {
        'familyTree': familyTree,
        'members': members,
      };
    } catch (e) {
      print('从云端同步失败: $e');
      return null;
    }
  }
}

