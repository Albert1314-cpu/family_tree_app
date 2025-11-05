import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/family_tree.dart';
import '../models/member.dart';
import '../models/relationship.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'family_tree.db';
  static const int _databaseVersion = 1;

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建族谱表
    await db.execute('''
      CREATE TABLE family_trees (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        surname TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_collaborative INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建成员表
    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        birthday TEXT,
        deathday TEXT,
        birth_place TEXT,
        occupation TEXT,
        notes TEXT,
        photo_path TEXT,
        generation INTEGER NOT NULL DEFAULT 0,
        ranking INTEGER NOT NULL DEFAULT 0,
        spouse_name TEXT,
        family_tree_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (family_tree_id) REFERENCES family_trees (id) ON DELETE CASCADE
      )
    ''');

    // 创建关系表
    await db.execute('''
      CREATE TABLE relationships (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        parent_id TEXT NOT NULL,
        child_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES members (id) ON DELETE CASCADE,
        FOREIGN KEY (child_id) REFERENCES members (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_members_family_tree_id ON members (family_tree_id)');
    await db.execute('CREATE INDEX idx_relationships_parent_id ON relationships (parent_id)');
    await db.execute('CREATE INDEX idx_relationships_child_id ON relationships (child_id)');
  }

  // 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 这里可以添加数据库升级逻辑
  }

  // 族谱相关操作
  Future<void> insertFamilyTree(FamilyTree familyTree) async {
    final db = await database;
    await db.insert('family_trees', familyTree.toMap());
  }

  Future<List<FamilyTree>> getAllFamilyTrees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('family_trees');
    return List.generate(maps.length, (i) => FamilyTree.fromMap(maps[i]));
  }

  Future<FamilyTree?> getFamilyTreeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'family_trees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FamilyTree.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateFamilyTree(FamilyTree familyTree) async {
    final db = await database;
    await db.update(
      'family_trees',
      familyTree.toMap(),
      where: 'id = ?',
      whereArgs: [familyTree.id],
    );
  }

  Future<void> deleteFamilyTree(String id) async {
    final db = await database;
    await db.delete(
      'family_trees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 成员相关操作
  Future<void> insertMember(Member member) async {
    final db = await database;
    await db.insert('members', member.toMap());
  }

  Future<List<Member>> getMembersByFamilyTreeId(String familyTreeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: 'family_tree_id = ?',
      whereArgs: [familyTreeId],
      orderBy: 'generation ASC, ranking ASC, name ASC',
    );
    return List.generate(maps.length, (i) => Member.fromMap(maps[i]));
  }

  Future<Member?> getMemberById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Member.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateMember(Member member) async {
    final db = await database;
    await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(String id) async {
    final db = await database;
    await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 关系相关操作
  Future<void> insertRelationship(Relationship relationship) async {
    final db = await database;
    await db.insert('relationships', relationship.toMap());
  }

  Future<List<Relationship>> getRelationshipsByMemberId(String memberId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'relationships',
      where: 'parent_id = ? OR child_id = ?',
      whereArgs: [memberId, memberId],
    );
    return List.generate(maps.length, (i) => Relationship.fromMap(maps[i]));
  }

  Future<List<Relationship>> getRelationshipsByFamilyTreeId(String familyTreeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT r.* FROM relationships r
      INNER JOIN members m1 ON r.parent_id = m1.id
      INNER JOIN members m2 ON r.child_id = m2.id
      WHERE m1.family_tree_id = ? AND m2.family_tree_id = ?
    ''', [familyTreeId, familyTreeId]);
    return List.generate(maps.length, (i) => Relationship.fromMap(maps[i]));
  }

  Future<void> updateRelationship(Relationship relationship) async {
    final db = await database;
    await db.update(
      'relationships',
      relationship.toMap(),
      where: 'id = ?',
      whereArgs: [relationship.id],
    );
  }

  Future<void> deleteRelationship(String id) async {
    final db = await database;
    await db.delete(
      'relationships',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除成员的所有关系
  Future<void> deleteRelationshipsByMemberId(String memberId) async {
    final db = await database;
    await db.delete(
      'relationships',
      where: 'parent_id = ? OR child_id = ? OR spouse1_id = ? OR spouse2_id = ?',
      whereArgs: [memberId, memberId, memberId, memberId],
    );
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
