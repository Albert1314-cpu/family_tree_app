import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/family_tree_provider.dart';
import '../models/family_tree.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../services/search_service.dart';
import 'create_family_tree_screen.dart';
import 'family_tree_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyTreeProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('族谱制作')
            : TypeAheadField<FamilyTree>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '搜索族谱...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final provider = context.read<FamilyTreeProvider>();
                  return SearchService.searchFamilyTrees(
                    familyTrees: provider.familyTrees,
                    query: pattern,
                  );
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.name),
                    subtitle: suggestion.description != null
                        ? Text(suggestion.description!)
                        : null,
                  );
                },
                onSuggestionSelected: (suggestion) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyTreeDetailScreen(
                        familyTree: suggestion,
                      ),
                    ),
                  );
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: _searchQuery.isEmpty
            ? IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _searchQuery = 'search';
                  });
                },
                tooltip: '搜索',
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
        actions: [
          if (_searchQuery.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {
                print('导入按钮被点击了！');
                _importFromCSV();
              },
              tooltip: '导入族谱',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateFamilyTreeScreen(),
                  ),
                );
              },
              tooltip: '新建族谱',
            ),
          ],
        ],
      ),
      body: Consumer<FamilyTreeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadFamilyTrees();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.familyTrees.isEmpty) {
            return _buildEmptyState();
          }

          // 如果正在搜索，显示搜索结果
          final displayTrees = _searchQuery.isNotEmpty && _searchController.text.isNotEmpty
              ? SearchService.searchFamilyTrees(
                  familyTrees: provider.familyTrees,
                  query: _searchController.text,
                )
              : provider.familyTrees;

          return _buildFamilyTreeList(displayTrees);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有族谱',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建您的第一个族谱',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTreeList(List<FamilyTree> familyTrees) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<FamilyTreeProvider>().loadFamilyTrees();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: familyTrees.length,
        itemBuilder: (context, index) {
          final familyTree = familyTrees[index];
          return _buildFamilyTreeCard(familyTree);
        },
      ),
    );
  }

  Widget _buildFamilyTreeCard(FamilyTree familyTree) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            familyTree.name.isNotEmpty ? familyTree.name[0].toUpperCase() : 'F',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          familyTree.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (familyTree.surname != null) ...[
              const SizedBox(height: 4),
              Text(
                '姓氏: ${familyTree.surname}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '创建时间: ${_formatDate(familyTree.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editFamilyTree(familyTree);
                break;
              case 'delete':
                _deleteFamilyTree(familyTree);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FamilyTreeDetailScreen(familyTree: familyTree),
            ),
          );
        },
      ),
    );
  }

  void _editFamilyTree(FamilyTree familyTree) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFamilyTreeScreen(
          familyTree: familyTree,
        ),
      ),
    );
  }

  void _deleteFamilyTree(FamilyTree familyTree) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除族谱'),
        content: Text('确定要删除族谱"${familyTree.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<FamilyTreeProvider>()
                  .deleteFamilyTree(familyTree.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('族谱删除成功')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.read<FamilyTreeProvider>().error ?? '删除失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _importFromCSV() async {
    print('导入CSV按钮被点击');
    _selectCSVFile();
  }

  void _selectCSVFile() async {
    try {
      print('尝试使用系统文件选择器...');
      
      // 尝试使用CSV文件类型
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择CSV文件',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        lockParentWindow: false,
      );
      
      print('文件选择结果: $result');
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        
        print('选择的文件: $fileName');
        print('文件路径: ${result.files.first.path}');
        
        if (fileName.toLowerCase().endsWith('.csv')) {
          print('开始读取CSV文件...');
          final csvContent = await file.readAsString(encoding: utf8);
          print('CSV内容长度: ${csvContent.length}');
          // 从文件名提取族谱名称（去掉.csv扩展名）
          final familyTreeName = fileName.replaceAll('.csv', '');
          await _processCSVContent(csvContent, familyTreeName);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('请选择CSV格式的文件'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('文件选择器返回null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未选择文件'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('文件选择错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件选择失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFileSelectionHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入族谱数据'),
        content: const Text('由于macOS系统限制，文件选择器可能无法正常弹出。\n\n请使用以下方式导入CSV数据：\n\n1. 复制CSV文件内容\n2. 点击"粘贴CSV内容"按钮\n3. 在文本框中粘贴数据\n4. 点击"导入"完成'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showTextInput();
            },
            child: const Text('粘贴CSV内容'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showTextInput() {
    final TextEditingController csvController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入族谱数据'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            children: [
              const Text(
                '由于macOS系统限制，请使用以下方式导入：\n\n1. 打开您的CSV文件\n2. 复制所有内容\n3. 粘贴到下方文本框\n4. 输入族谱名称（可选）\n5. 点击导入',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '族谱名称（可选）',
                  hintText: '例如：张氏族谱、李氏家族等',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: csvController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '请粘贴CSV内容：\n\n姓名,性别,世代,排行,出生日期,父亲姓名,母亲姓名,配偶姓名,备注\n大年,男,第1代,长子,1920-01-01,,,李秀英,家族第一代\n李秀英,女,第1代,长女,1922-03-15,,,大年,大年配偶',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final csvContent = csvController.text.trim();
              final familyTreeName = nameController.text.trim();
              
              if (csvContent.isNotEmpty) {
                await _processCSVContent(csvContent, familyTreeName.isNotEmpty ? familyTreeName : null);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入CSV内容'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }



  Map<String, dynamic>? _parseCSVContent(String csvContent, [String? familyTreeName]) {
    try {
      final lines = csvContent.trim().split('\n');
      if (lines.isEmpty) return null;
      
      // 检查头部格式
      final header = lines[0].trim();
      if (header != '姓名,性别,世代,排行,出生日期,父亲姓名,母亲姓名,配偶姓名,备注') {
        return null;
      }
      
      final members = <Map<String, dynamic>>[];
      
      // 解析数据行
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final fields = _parseCSVLine(line);
        if (fields.length >= 9) {
          members.add({
            'name': fields[0],
            'gender': _parseGender(fields[1]),
            'generation': _parseGeneration(fields[2]),
            'ranking': _parseRanking(fields[3], _parseGender(fields[1])),
            'birthday': _parseBirthday(fields[4]),
            'fatherName': fields[5],
            'motherName': fields[6],
            'spouseName': fields[7],
            'notes': fields[8],
          });
        }
      }
      
      if (members.isEmpty) return null;
      
      // 确定族谱名称
      String finalFamilyTreeName;
      if (familyTreeName != null && familyTreeName.isNotEmpty) {
        // 使用文件名作为族谱名称
        finalFamilyTreeName = familyTreeName;
      } else {
        // 从第一个成员推断族谱名称
        final firstMember = members.first;
        final surname = firstMember['name'].toString().isNotEmpty 
            ? firstMember['name'].toString()[0] 
            : '导入';
        finalFamilyTreeName = '${surname}氏族谱';
      }
      
      // 从族谱名称推断姓氏
      final surname = finalFamilyTreeName.isNotEmpty 
          ? finalFamilyTreeName[0] 
          : (members.first['name'].toString().isNotEmpty 
              ? members.first['name'].toString()[0] 
              : '导入');
      
      return {
        'name': finalFamilyTreeName,
        'surname': surname,
        'members': members,
      };
    } catch (e) {
      print('CSV解析错误: $e');
      return null;
    }
  }

  List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    fields.add(currentField.trim());
    return fields;
  }

  Gender _parseGender(String genderStr) {
    switch (genderStr.trim()) {
      case '男':
        return Gender.male;
      case '女':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  int _parseGeneration(String generationStr) {
    final match = RegExp(r'第(\d+)代').firstMatch(generationStr.trim());
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  int _parseRanking(String rankingStr, Gender gender) {
    final ranking = rankingStr.trim();
    if (ranking == '未知') return 0;
    
    if (gender == Gender.male) {
      switch (ranking) {
        case '长子': return 1;
        case '次子': return 2;
        case '三子': return 3;
        case '四子': return 4;
        case '五子': return 5;
        default:
          final match = RegExp(r'第(\d+)个').firstMatch(ranking);
          if (match != null) {
            return int.tryParse(match.group(1)!) ?? 0;
          }
          return 0;
      }
    } else {
      switch (ranking) {
        case '长女': return 1;
        case '次女': return 2;
        case '三女': return 3;
        case '四女': return 4;
        case '五女': return 5;
        default:
          final match = RegExp(r'第(\d+)个').firstMatch(ranking);
          if (match != null) {
            return int.tryParse(match.group(1)!) ?? 0;
          }
          return 0;
      }
    }
  }

  DateTime? _parseBirthday(String birthdayStr) {
    if (birthdayStr.trim().isEmpty) return null;
    
    try {
      final parts = birthdayStr.trim().split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      print('日期解析错误: $e');
    }
    
    return null;
  }

  Future<bool> _importFamilyTreeData(Map<String, dynamic> data) async {
    try {
      final provider = context.read<FamilyTreeProvider>();
      final membersData = data['members'] as List<Map<String, dynamic>>;
      
      // 创建族谱
      final familyTree = FamilyTree(
        name: data['name'] ?? '导入的族谱',
        surname: data['surname'],
      );
      
      // 创建成员映射（姓名 -> 成员对象）
      final memberNameToMember = <String, Member>{};
      final members = <Member>[];
      final relationships = <Relationship>[];
      
      // 创建所有成员
      for (final memberData in membersData) {
        final member = Member(
          name: memberData['name'],
          gender: memberData['gender'],
          generation: memberData['generation'],
          ranking: memberData['ranking'],
          birthday: memberData['birthday'],
          notes: memberData['notes'],
          familyTreeId: familyTree.id,
        );
        
        members.add(member);
        memberNameToMember[member.name] = member;
      }
      
      // 创建关系
      for (final memberData in membersData) {
        final member = memberNameToMember[memberData['name']];
        if (member == null) continue;
        
        // 创建父子关系
        if (memberData['fatherName'].toString().isNotEmpty) {
          final father = memberNameToMember[memberData['fatherName']];
          if (father != null) {
            final relationship = Relationship.parentChild(
              parentId: father.id,
              childId: member.id,
            );
            relationships.add(relationship);
          }
        }
        
        // 创建配偶关系
        if (memberData['spouseName'].toString().isNotEmpty) {
          final spouse = memberNameToMember[memberData['spouseName']];
          if (spouse != null) {
            final relationship = Relationship.spouse(
              spouse1Id: member.id,
              spouse2Id: spouse.id,
            );
            relationships.add(relationship);
          }
        }
      }
      
      // 使用 createFamilyTreeWithData 一次性创建族谱和所有数据
      return await provider.createFamilyTreeWithData(familyTree, members, relationships);
    } catch (e) {
      print('导入族谱数据失败: $e');
      return false;
    }
  }


  Future<void> _processCSVContent(String csvContent, [String? familyTreeName]) async {
    try {
      print('开始处理CSV内容...');
      
      // 解析CSV内容
      final familyTreeData = _parseCSVContent(csvContent, familyTreeName);
      
      if (familyTreeData != null) {
        // 创建族谱、成员和关系
        final success = await _importFamilyTreeData(familyTreeData);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV导入成功！'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导入失败，请检查CSV格式'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV格式不正确，请检查文件内容'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}


