import 'package:uuid/uuid.dart';

enum RelationshipType { parentChild, spouse }

class Relationship {
  final String id;
  final RelationshipType type;
  final String parentId; // 对于parentChild关系，这是父ID；对于spouse关系，这是配偶1的ID
  final String childId;  // 对于parentChild关系，这是子ID；对于spouse关系，这是配偶2的ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Relationship({
    String? id,
    required this.type,
    required this.parentId,
    required this.childId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 创建父子关系
  factory Relationship.parentChild({
    required String parentId,
    required String childId,
  }) {
    return Relationship(
      type: RelationshipType.parentChild,
      parentId: parentId,
      childId: childId,
    );
  }

  // 创建配偶关系
  factory Relationship.spouse({
    required String spouse1Id,
    required String spouse2Id,
  }) {
    return Relationship(
      type: RelationshipType.spouse,
      parentId: spouse1Id,
      childId: spouse2Id,
    );
  }

  // 从数据库创建对象
  factory Relationship.fromMap(Map<String, dynamic> map) {
    return Relationship(
      id: map['id'],
      type: _parseRelationshipType(map['type']),
      parentId: map['parent_id'],
      childId: map['child_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 转换为数据库格式
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': _relationshipTypeToString(type),
      'parent_id': parentId,
      'child_id': childId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 复制并更新
  Relationship copyWith({
    RelationshipType? type,
    String? parentId,
    String? childId,
  }) {
    return Relationship(
      id: id,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // 检查关系是否包含指定成员
  bool containsMember(String memberId) {
    return parentId == memberId || childId == memberId;
  }

  // 获取关系中的另一个成员ID
  String getOtherMemberId(String memberId) {
    if (parentId == memberId) return childId;
    if (childId == memberId) return parentId;
    throw ArgumentError('Member $memberId is not part of this relationship');
  }

  // 获取关系中的两个成员ID
  List<String> get memberIds => [parentId, childId];

  @override
  String toString() {
    return 'Relationship(id: $id, type: $type, parentId: $parentId, childId: $childId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Relationship && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // 解析关系类型字符串为RelationshipType枚举
  static RelationshipType _parseRelationshipType(String? typeString) {
    switch (typeString) {
      case 'parentChild':
        return RelationshipType.parentChild;
      case 'spouse':
        return RelationshipType.spouse;
      default:
        return RelationshipType.parentChild;
    }
  }

  // 将RelationshipType枚举转换为字符串
  static String _relationshipTypeToString(RelationshipType type) {
    switch (type) {
      case RelationshipType.parentChild:
        return 'parentChild';
      case RelationshipType.spouse:
        return 'spouse';
    }
  }
}
