import 'package:uuid/uuid.dart';

class FamilyTree {
  final String id;
  final String name;
  final String? surname;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCollaborative;

  FamilyTree({
    String? id,
    required this.name,
    this.surname,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isCollaborative = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 从数据库创建对象
  factory FamilyTree.fromMap(Map<String, dynamic> map) {
    return FamilyTree(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isCollaborative: map['is_collaborative'] == 1,
    );
  }

  // 转换为数据库格式
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_collaborative': isCollaborative ? 1 : 0,
    };
  }

  // 复制并更新
  FamilyTree copyWith({
    String? name,
    String? surname,
    String? notes,
    bool? isCollaborative,
  }) {
    return FamilyTree(
      id: id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isCollaborative: isCollaborative ?? this.isCollaborative,
    );
  }

  @override
  String toString() {
    return 'FamilyTree(id: $id, name: $name, surname: $surname, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, isCollaborative: $isCollaborative)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyTree && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

