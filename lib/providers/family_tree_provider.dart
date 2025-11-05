import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/family_tree.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../services/database_service.dart';
import '../services/cloud_sync_service.dart';

class FamilyTreeProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  
  List<FamilyTree> _familyTrees = [];
  List<Member> _members = [];
  List<Relationship> _relationships = [];
  
  FamilyTree? _selectedFamilyTree;
  Member? _selectedMember;
  
  // 存储协作家族树的 ownerId（key: familyTreeId, value: ownerId）
  final Map<String, String> _collaborativeTreeOwners = {};
  
  // 实时监听订阅
  StreamSubscription<List<Member>>? _membersSubscription;
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<FamilyTree> get familyTrees => _familyTrees;
  List<Member> get members => _members;
  List<Relationship> get relationships => _relationships;
  FamilyTree? get selectedFamilyTree => _selectedFamilyTree;
  Member? get selectedMember => _selectedMember;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 初始化
  Future<void> initialize() async {
    await loadFamilyTrees();
  }

  // 加载所有族谱
  Future<void> loadFamilyTrees() async {
    _setLoading(true);
    try {
      _familyTrees = await _databaseService.getAllFamilyTrees();
      _error = null;
    } catch (e) {
      _error = '加载族谱失败: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 创建族谱
  Future<bool> createFamilyTree({
    required String name,
    String? surname,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final familyTree = FamilyTree(
        name: name,
        surname: surname,
        notes: notes,
      );
      
      await _databaseService.insertFamilyTree(familyTree);
      await loadFamilyTrees();
      _error = null;
      return true;
    } catch (e) {
      _error = '创建族谱失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 创建族谱并导入数据
  Future<bool> createFamilyTreeWithData(
    FamilyTree familyTree,
    List<Member> members,
    List<Relationship> relationships,
  ) async {
    _setLoading(true);
    try {
      // 创建族谱
      await _databaseService.insertFamilyTree(familyTree);
      
      // 添加成员
      for (final member in members) {
        await _databaseService.insertMember(member);
      }
      
      // 添加关系
      for (final relationship in relationships) {
        await _databaseService.insertRelationship(relationship);
      }
      
      await loadFamilyTrees();
      _error = null;
      return true;
    } catch (e) {
      _error = '导入族谱失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新族谱
  Future<bool> updateFamilyTree(FamilyTree familyTree) async {
    _setLoading(true);
    try {
      await _databaseService.updateFamilyTree(familyTree);
      await loadFamilyTrees();
      _error = null;
      return true;
    } catch (e) {
      _error = '更新族谱失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除族谱
  Future<bool> deleteFamilyTree(String id) async {
    _setLoading(true);
    try {
      await _databaseService.deleteFamilyTree(id);
      await loadFamilyTrees();
      if (_selectedFamilyTree?.id == id) {
        _selectedFamilyTree = null;
        _members = [];
        _relationships = [];
      }
      _error = null;
      return true;
    } catch (e) {
      _error = '删除族谱失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 选择族谱
  Future<void> selectFamilyTree(FamilyTree familyTree) async {
    // 先停止之前的监听
    await stopRealtimeSync();
    
    _selectedFamilyTree = familyTree;
    
    // 如果是协作家族树，启动实时监听
    if (familyTree.isCollaborative) {
      await startRealtimeSync(familyTree.id);
    } else {
      await loadMembers(familyTree.id);
    }
    
    notifyListeners();
  }
  
  // 启动实时同步（监听云端变化）
  Future<void> startRealtimeSync(String familyTreeId) async {
    // 先停止之前的监听
    await stopRealtimeSync();
    
    try {
      // 获取 ownerId
      String? ownerId = _collaborativeTreeOwners[familyTreeId];
      
      if (ownerId == null) {
        print('协作家族树未找到 ownerId，尝试从本地加载');
        // 如果没有 ownerId，先尝试从本地加载
        _members = await _databaseService.getMembersByFamilyTreeId(familyTreeId);
        if (_members.isEmpty) {
          _error = '协作家族树需要重新访问分享码来加载数据';
          notifyListeners();
          return;
        }
        // 从本地加载关系
        _relationships = [];
        for (final member in _members) {
          final memberRelationships = await _databaseService.getRelationshipsByMemberId(member.id);
          _relationships.addAll(memberRelationships);
        }
        _relationships = _relationships.toSet().toList();
        notifyListeners();
        return;
      }
      
      // 先加载一次初始数据
      _members = await _cloudSyncService.loadCollaborativeMembers(familyTreeId, ownerId);
      print('初始加载了 ${_members.length} 个协作成员');
      
      // 加载关系（从本地数据库）
      _relationships = [];
      for (final member in _members) {
        final memberRelationships = await _databaseService.getRelationshipsByMemberId(member.id);
        _relationships.addAll(memberRelationships);
      }
      _relationships = _relationships.toSet().toList();
      
      // 启动实时监听
      _membersSubscription = _cloudSyncService
          .watchCollaborativeMembers(familyTreeId, ownerId)
          .listen(
        (cloudMembers) {
          print('📡 收到云端更新: ${cloudMembers.length} 个成员');
          
          // 更新成员列表
          _members = cloudMembers;
          
          // 同步到本地数据库（保持数据一致性）
          _syncMembersToLocal(cloudMembers, familyTreeId);
          
          // 重新加载关系
          _loadRelationshipsFromLocal();
          
          // 通知UI更新
          notifyListeners();
        },
        onError: (error) {
          print('实时监听错误: $error');
          _error = '实时同步失败: $error';
          notifyListeners();
        },
      );
      
      print('✅ 已启动实时同步监听: familyTreeId=$familyTreeId, ownerId=$ownerId');
      _error = null;
    } catch (e) {
      print('启动实时同步失败: $e');
      _error = '启动实时同步失败: $e';
      // 失败时尝试从本地加载
      try {
        _members = await _databaseService.getMembersByFamilyTreeId(familyTreeId);
        _loadRelationshipsFromLocal();
      } catch (e2) {
        print('从本地加载也失败: $e2');
      }
    } finally {
      notifyListeners();
    }
  }
  
  // 停止实时同步
  Future<void> stopRealtimeSync() async {
    if (_membersSubscription != null) {
      await _membersSubscription!.cancel();
      _membersSubscription = null;
      print('🛑 已停止实时同步监听');
    }
  }
  
  // 同步成员到本地数据库
  Future<void> _syncMembersToLocal(List<Member> cloudMembers, String familyTreeId) async {
    try {
      // 获取本地现有成员
      final localMembers = await _databaseService.getMembersByFamilyTreeId(familyTreeId);
      final localMemberIds = localMembers.map((m) => m.id).toSet();
      final cloudMemberIds = cloudMembers.map((m) => m.id).toSet();
      
      // 删除本地已不存在的成员
      for (final localMember in localMembers) {
        if (!cloudMemberIds.contains(localMember.id)) {
          await _databaseService.deleteMember(localMember.id);
        }
      }
      
      // 更新或插入成员
      for (final cloudMember in cloudMembers) {
        if (localMemberIds.contains(cloudMember.id)) {
          // 更新现有成员
          await _databaseService.updateMember(cloudMember);
        } else {
          // 插入新成员
          await _databaseService.insertMember(cloudMember);
        }
      }
      
      print('✅ 已同步 ${cloudMembers.length} 个成员到本地数据库');
    } catch (e) {
      print('同步成员到本地失败: $e');
    }
  }
  
  // 从本地数据库加载关系
  Future<void> _loadRelationshipsFromLocal() async {
    try {
      _relationships = [];
      for (final member in _members) {
        final memberRelationships = await _databaseService.getRelationshipsByMemberId(member.id);
        _relationships.addAll(memberRelationships);
      }
      _relationships = _relationships.toSet().toList();
    } catch (e) {
      print('加载关系失败: $e');
    }
  }

  // 设置协作家族树的 ownerId
  void setCollaborativeTreeOwner(String familyTreeId, String ownerId) {
    _collaborativeTreeOwners[familyTreeId] = ownerId;
  }

  // 添加协作家族树到本地数据库（用于访问分享的家族树）
  Future<bool> addCollaborativeFamilyTree(FamilyTree familyTree) async {
    try {
      // 检查是否已存在
      final existingTrees = await _databaseService.getAllFamilyTrees();
      if (existingTrees.any((tree) => tree.id == familyTree.id)) {
        print('家族树 ${familyTree.name} 已存在于本地数据库');
        await loadFamilyTrees(); // 刷新列表
        return true;
      }
      
      // 保存到本地数据库
      await _databaseService.insertFamilyTree(familyTree);
      
      // 刷新家族树列表
      await loadFamilyTrees();
      
      print('已添加协作家族树到本地: ${familyTree.name}');
      return true;
    } catch (e) {
      print('添加协作家族树失败: $e');
      _error = '添加协作家族树失败: $e';
      return false;
    }
  }

  // 清理资源（停止实时监听）
  @override
  void dispose() {
    stopRealtimeSync();
    super.dispose();
  }

  // 加载成员（从本地数据库）
  Future<void> loadMembers(String familyTreeId) async {
    _setLoading(true);
    try {
      _members = await _databaseService.getMembersByFamilyTreeId(familyTreeId);
      print('加载了 ${_members.length} 个成员');
      _relationships = [];
      
      // 加载所有关系
      for (final member in _members) {
        final memberRelationships = await _databaseService.getRelationshipsByMemberId(member.id);
        print('成员 ${member.name} 有 ${memberRelationships.length} 个关系');
        _relationships.addAll(memberRelationships);
      }
      
      // 去重
      _relationships = _relationships.toSet().toList();
      print('总共加载了 ${_relationships.length} 个关系');
      
      _error = null;
    } catch (e) {
      print('加载成员失败: $e');
      _error = '加载成员失败: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 创建成员
  Future<String?> createMember({
    required String name,
    required String familyTreeId,
    String? gender,
    DateTime? birthday,
    DateTime? deathday,
    String? birthPlace,
    String? occupation,
    String? notes,
    String? photoPath,
    int generation = 0,
    int ranking = 0,
    String? spouseName,
    String? memberId, // 可选：指定成员ID（用于从云端下载时保持原始ID）
  }) async {
    _setLoading(true);
    try {
      final member = Member(
        id: memberId, // 如果提供了ID，使用它；否则自动生成
        name: name,
        gender: gender == 'male' ? Gender.male : 
                gender == 'female' ? Gender.female : Gender.other,
        birthday: birthday,
        deathday: deathday,
        birthPlace: birthPlace,
        occupation: occupation,
        notes: notes,
        photoPath: photoPath,
        generation: generation,
        ranking: ranking,
        spouseName: spouseName,
        familyTreeId: familyTreeId,
      );
      
      // 先保存到本地数据库
      await _databaseService.insertMember(member);
      
      // 如果是协作家族树，同时上传到云端（触发实时同步）
      if (_selectedFamilyTree?.isCollaborative == true) {
        final ownerId = _collaborativeTreeOwners[familyTreeId];
        if (ownerId != null) {
          try {
            await _cloudSyncService.uploadMemberToCollaborativeTree(
              familyTreeId,
              ownerId,
              member,
            );
            print('✅ 已同步新成员到云端: ${member.name}');
          } catch (e) {
            print('⚠️ 上传成员到云端失败（本地已保存）: $e');
            // 本地保存成功，但云端上传失败，不影响本地使用
          }
        }
      }
      
      // 如果是非协作树，使用原来的加载方式
      if (_selectedFamilyTree?.isCollaborative != true) {
        await loadMembers(familyTreeId);
      }
      // 协作树会通过实时监听自动更新，不需要手动加载
      
      _error = null;
      return member.id; // 返回新创建的成员ID
    } catch (e) {
      _error = '创建成员失败: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // 批量保存从云端下载的成员（保持原始ID）
  Future<int> saveDownloadedMembers(List<Member> members) async {
    int savedCount = 0;
    _setLoading(true);
    try {
      for (final member in members) {
        try {
          // 检查是否已存在
          final existing = await _databaseService.getMemberById(member.id);
          if (existing != null) {
            // 更新现有成员
            await _databaseService.updateMember(member);
          } else {
            // 插入新成员
            await _databaseService.insertMember(member);
          }
          savedCount++;
        } catch (e) {
          print('保存成员 ${member.name} 失败: $e');
        }
      }
      
      // 重新加载成员列表
      if (members.isNotEmpty) {
        await loadMembers(members.first.familyTreeId);
      }
      
      _error = null;
      return savedCount;
    } catch (e) {
      _error = '批量保存成员失败: $e';
      return savedCount;
    } finally {
      _setLoading(false);
    }
  }

  // 更新成员
  Future<bool> updateMember(Member member) async {
    _setLoading(true);
    try {
      // 先更新本地数据库
      await _databaseService.updateMember(member);
      
      // 如果是协作家族树，同时上传到云端（触发实时同步）
      if (_selectedFamilyTree?.isCollaborative == true) {
        final ownerId = _collaborativeTreeOwners[member.familyTreeId];
        if (ownerId != null) {
          try {
            await _cloudSyncService.uploadMemberToCollaborativeTree(
              member.familyTreeId,
              ownerId,
              member,
            );
            print('✅ 已同步成员更新到云端: ${member.name}');
          } catch (e) {
            print('⚠️ 上传成员更新到云端失败（本地已更新）: $e');
            // 本地更新成功，但云端上传失败，不影响本地使用
          }
        }
      }
      
      // 如果是非协作树，使用原来的加载方式
      if (_selectedFamilyTree?.isCollaborative != true) {
        await loadMembers(member.familyTreeId);
      }
      // 协作树会通过实时监听自动更新，不需要手动加载
      
      _error = null;
      return true;
    } catch (e) {
      _error = '更新成员失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除成员
  Future<bool> deleteMember(String id) async {
    _setLoading(true);
    try {
      final member = _members.firstWhere((m) => m.id == id);
      
      // 先删除本地数据库
      await _databaseService.deleteMember(id);
      
      // 如果是协作家族树，同时从云端删除（触发实时同步）
      if (_selectedFamilyTree?.isCollaborative == true) {
        final ownerId = _collaborativeTreeOwners[member.familyTreeId];
        if (ownerId != null) {
          try {
            await _cloudSyncService.deleteMemberFromCollaborativeTree(
              member.familyTreeId,
              ownerId,
              id,
            );
            print('✅ 已同步删除成员到云端: ${member.name}');
          } catch (e) {
            print('⚠️ 从云端删除成员失败（本地已删除）: $e');
            // 本地删除成功，但云端删除失败，不影响本地使用
          }
        }
      }
      
      // 如果是非协作树，使用原来的加载方式
      if (_selectedFamilyTree?.isCollaborative != true) {
        await loadMembers(member.familyTreeId);
      }
      // 协作树会通过实时监听自动更新，不需要手动加载
      
      if (_selectedMember?.id == id) {
        _selectedMember = null;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = '删除成员失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 创建父子关系
  Future<bool> createParentChildRelationship(String parentId, String childId) async {
    _setLoading(true);
    try {
      final relationship = Relationship.parentChild(
        parentId: parentId,
        childId: childId,
      );
      
      print('创建父子关系: $parentId -> $childId');
      await _databaseService.insertRelationship(relationship);
      print('关系已保存到数据库');
      
      if (_selectedFamilyTree != null) {
        await loadMembers(_selectedFamilyTree!.id);
        print('重新加载成员，当前关系数: ${_relationships.length}');
      }
      _error = null;
      return true;
    } catch (e) {
      print('创建关系失败: $e');
      _error = '创建关系失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 创建配偶关系
  Future<bool> createSpouseRelationship(String spouse1Id, String spouse2Id) async {
    _setLoading(true);
    try {
      final relationship = Relationship.spouse(
        spouse1Id: spouse1Id,
        spouse2Id: spouse2Id,
      );
      
      await _databaseService.insertRelationship(relationship);
      if (_selectedFamilyTree != null) {
        await loadMembers(_selectedFamilyTree!.id);
      }
      _error = null;
      return true;
    } catch (e) {
      _error = '创建关系失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 获取成员的子女
  List<Member> getChildren(String memberId) {
    return _relationships
        .where((r) => r.type == RelationshipType.parentChild && r.parentId == memberId)
        .map((r) => _members.firstWhere((m) => m.id == r.childId))
        .toList();
  }

  // 获取成员的父母
  List<Member> getParents(String memberId) {
    return _relationships
        .where((r) => r.type == RelationshipType.parentChild && r.childId == memberId)
        .map((r) => _members.firstWhere((m) => m.id == r.parentId))
        .toList();
  }

  // 获取成员的配偶
  List<Member> getSpouses(String memberId) {
    return _relationships
        .where((r) => r.type == RelationshipType.spouse && r.containsMember(memberId))
        .map((r) => _members.firstWhere((m) => m.id == r.getOtherMemberId(memberId)))
        .toList();
  }

  // 删除成员的所有关系
  Future<bool> deleteRelationshipsByMemberId(String memberId) async {
    _setLoading(true);
    try {
      print('删除成员 $memberId 的所有关系');
      await _databaseService.deleteRelationshipsByMemberId(memberId);
      
      if (_selectedFamilyTree != null) {
        await loadMembers(_selectedFamilyTree!.id);
        print('重新加载成员，当前关系数: ${_relationships.length}');
      }
      _error = null;
      return true;
    } catch (e) {
      print('删除关系失败: $e');
      _error = '删除关系失败: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 选择成员
  void selectMember(Member member) {
    _selectedMember = member;
    notifyListeners();
  }

  // 清除选择
  void clearSelection() {
    _selectedMember = null;
    notifyListeners();
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

