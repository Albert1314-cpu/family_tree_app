import 'package:uuid/uuid.dart';

enum Gender { male, female, other }

class Member {
  final String id;
  final String name;
  final Gender gender;
  final DateTime? birthday;
  final DateTime? deathday;
  final String? birthPlace;
  final String? occupation;
  final String? notes;
  final String? photoPath;
  final int generation;
  final int ranking;
  final String? spouseName;
  final String familyTreeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    String? id,
    required this.name,
    required this.gender,
    this.birthday,
    this.deathday,
    this.birthPlace,
    this.occupation,
    this.notes,
    this.photoPath,
    this.generation = 0,
    this.ranking = 0,
    this.spouseName,
    required this.familyTreeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 从数据库创建对象
  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      gender: _parseGender(map['gender']),
      birthday: map['birthday'] != null ? DateTime.parse(map['birthday']) : null,
      deathday: map['deathday'] != null ? DateTime.parse(map['deathday']) : null,
      birthPlace: map['birth_place'],
      occupation: map['occupation'],
      notes: map['notes'],
      photoPath: map['photo_path'],
      generation: map['generation'] ?? 0,
      ranking: map['ranking'] ?? 0,
      spouseName: map['spouse_name'],
      familyTreeId: map['family_tree_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 转换为数据库格式
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': _genderToString(gender),
      'birthday': birthday?.toIso8601String(),
      'deathday': deathday?.toIso8601String(),
      'birth_place': birthPlace,
      'occupation': occupation,
      'notes': notes,
      'photo_path': photoPath,
      'generation': generation,
      'ranking': ranking,
      'spouse_name': spouseName,
      'family_tree_id': familyTreeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 复制并更新
  Member copyWith({
    String? name,
    Gender? gender,
    DateTime? birthday,
    DateTime? deathday,
    String? birthPlace,
    String? occupation,
    String? notes,
    String? photoPath,
    int? generation,
    int? ranking,
    String? spouseName,
  }) {
    return Member(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      deathday: deathday ?? this.deathday,
      birthPlace: birthPlace ?? this.birthPlace,
      occupation: occupation ?? this.occupation,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      generation: generation ?? this.generation,
      ranking: ranking ?? this.ranking,
      spouseName: spouseName ?? this.spouseName,
      familyTreeId: familyTreeId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // 获取年龄
  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    final birth = birthday!;
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  // 是否已故
  bool get isDeceased => deathday != null;

  @override
  String toString() {
    return 'Member(id: $id, name: $name, gender: $gender, birthday: $birthday, deathday: $deathday, birthPlace: $birthPlace, occupation: $occupation, notes: $notes, photoPath: $photoPath, generation: $generation, ranking: $ranking, spouseName: $spouseName, familyTreeId: $familyTreeId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Member && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // 解析性别字符串为Gender枚举
  static Gender _parseGender(String? genderString) {
    switch (genderString) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  // 将Gender枚举转换为字符串
  static String _genderToString(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
    }
  }
}
