import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import '../models/family_tree.dart';
import '../models/member.dart';
import '../models/relationship.dart';

// 树形布局数据结构
class TreeLayout {
  final Map<Member, Offset> positions;
  final Map<Member, List<Member>> children;
  final Map<Member, List<Member>> spouses;
  final Member? root;
  final double width;
  final double height;

  TreeLayout({
    required this.positions,
    required this.children,
    required this.spouses,
    this.root,
    required this.width,
    required this.height,
  });
}

class FamilyTreeVisualizationScreen extends StatefulWidget {
  final FamilyTree familyTree;
  final List<Member> members;
  final List<Relationship> relationships;

  const FamilyTreeVisualizationScreen({
    super.key,
    required this.familyTree,
    required this.members,
    required this.relationships,
  });

  @override
  State<FamilyTreeVisualizationScreen> createState() => _FamilyTreeVisualizationScreenState();
}

class _FamilyTreeVisualizationScreenState extends State<FamilyTreeVisualizationScreen> {
  late TreeLayout _treeLayout;
  Member? _selectedMember;

  @override
  void initState() {
    super.initState();
    _calculateTreeLayout();
    // 调试信息
    print('族谱图初始化: ${widget.members.length} 个成员, ${widget.relationships.length} 个关系');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            minScale: 0.2,  // 最小缩放比例
            maxScale: 3.0,  // 最大缩放比例
            boundaryMargin: const EdgeInsets.all(20),  // 边界边距
            constrained: false,  // 允许超出屏幕边界
            child: Container(
              width: _treeLayout.width,
              height: _treeLayout.height,
              color: Colors.white,
              child: Stack(
                children: [
                  // 关系线层
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RelationshipPainter(
                        treeLayout: _treeLayout,
                        selectedMember: _selectedMember,
                      ),
                    ),
                  ),
                  // 世代标签层
                  _buildGenerationLabels(),
                  // 节点层（最上层）
                  _buildMemberNodes(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildGenerationLabels() {
    // 获取所有世代
    final generations = <int>{};
    for (final member in widget.members) {
      generations.add(member.generation);
    }
    
    final sortedGenerations = generations.toList()..sort();
    
    return Stack(
      children: sortedGenerations.map((generation) {
        // 找到该世代的第一个成员位置作为标签位置
        final membersInGeneration = widget.members
            .where((m) => m.generation == generation)
            .where((m) => _treeLayout.positions.containsKey(m))
            .toList();
        
        if (membersInGeneration.isEmpty) return const SizedBox.shrink();
        
        // 使用该世代第一个成员的位置
        final firstMember = membersInGeneration.first;
        final position = _treeLayout.positions[firstMember]!;
        
        return Positioned(
          left: 10, // 左侧边距
          top: position.dy - 20, // 在节点上方
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent, width: 1),
            ),
            child: Text(
              '第${generation}代',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberNodes() {
    print('构建节点: ${_treeLayout.positions.length} 个节点');
    return Stack(
      children: _treeLayout.positions.entries.map((entry) {
        final member = entry.key;
        final position = entry.value;
        final isSelected = _selectedMember?.id == member.id;
        
        print('节点 ${member.name}: 位置(${position.dx}, ${position.dy})');
        
        return Positioned(
          left: position.dx - 30,  // 调整为中心位置 (60/2=30)
          top: position.dy - 30,   // 调整为中心位置 (60/2=30)
          child: GestureDetector(
            onTap: () => _showMemberDetails(member),
            onLongPress: () => _selectMember(member),
            child: Container(
              width: 60,  // 保持60x60节点大小
              height: 60, // 保持60x60节点大小
              decoration: BoxDecoration(
                color: Colors.white,  // 统一白色背景
                borderRadius: BorderRadius.circular(8),  // 圆角矩形，与桌面版本一致
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFFFFF) : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),  // 轻微阴影，与桌面版本一致
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 1), // 头像距离顶部1像素
                  // 性别图标 - 改进头像显示
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: _getGenderColor(member.gender),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      _getGenderIcon(member.gender),
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 姓名
                  Text(
                    member.name.isNotEmpty ? member.name : '?',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 28,  // 与桌面应用一致
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getMemberColor(Member member) {
    switch (member.gender) {
      case Gender.male:
        return const Color(0xFF1976D2); // 男性蓝色
      case Gender.female:
        return const Color(0xFFD32F2F); // 女性红色
      case Gender.other:
        return const Color(0xFF808080); // 其他灰色
    }
  }

  // 获取性别图标
  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Icons.person;  // 男性图标
      case Gender.female:
        return Icons.person;  // 女性图标
      case Gender.other:
        return Icons.person_outline;  // 其他性别图标
    }
  }

  // 获取性别颜色
  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return const Color(0xFF1976D2);  // 男性蓝色
      case Gender.female:
        return const Color(0xFFD32F2F);  // 女性红色
      case Gender.other:
        return const Color(0xFF808080);  // 其他灰色
    }
  }

  void _adjustMultiParentChildrenPositions(Map<int, List<Member>> generations, Map<Member, List<Member>> children) {
    // 找到有多个父母的子节点，并调整其位置
    final Map<Member, List<Member>> parentMap = {};
    
    // 构建父母映射
    for (final entry in children.entries) {
      final parent = entry.key;
      final childList = entry.value;
      for (final child in childList) {
        if (!parentMap.containsKey(child)) {
          parentMap[child] = [];
        }
        parentMap[child]!.add(parent);
      }
    }
    
    // 处理有多个父母的子节点
    for (final entry in parentMap.entries) {
      final child = entry.key;
      final parents = entry.value;
      
      if (parents.length > 1) {
        print('发现多父母子节点: ${child.name}, 父母: ${parents.map((p) => p.name).join(', ')}');
        
        // 将子节点移动到父母中间位置
        final parentGeneration = parents.first.generation;
        final childGeneration = child.generation;
        
        // 确保子节点在正确的世代中
        if (generations.containsKey(childGeneration)) {
          generations[childGeneration]!.remove(child);
        }
        
        // 将子节点添加到正确的世代
        if (!generations.containsKey(childGeneration)) {
          generations[childGeneration] = [];
        }
        generations[childGeneration]!.add(child);
      }
    }
  }

  void _calculateTreeLayout([Size? screenSize]) {
    if (widget.members.isEmpty) {
      _treeLayout = TreeLayout(
        positions: {},
        children: {},
        spouses: {},
        width: 400,
        height: 400,
      );
      return;
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
      
      print('处理关系: ${relationship.type} - ${member1?.name} -> ${member2?.name}');
      
      if (member1 != null && member2 != null) {
        if (relationship.type == RelationshipType.parentChild) {
          children[member1]!.add(member2);
          print('添加父子关系: ${member1.name} -> ${member2.name}');
        } else if (relationship.type == RelationshipType.spouse) {
          spouses[member1]!.add(member2);
          spouses[member2]!.add(member1);
          print('添加配偶关系: ${member1.name} <-> ${member2.name}');
        }
      } else {
        print('关系成员未找到: ${relationship.parentId} -> ${relationship.childId}');
      }
    }

    // 使用桌面版本的递归布局算法计算布局
    final positions = <Member, Offset>{};
    final nodeSpacing = 60.0; // 节点间距 (水平间距60像素)
    final levelHeight = 120.0; // 世代间距 (垂直间距120像素)
    final margin = 50.0; // 边距
    
    // 世代标准化：找到最小世代值，用于位置计算偏移
    final minGeneration = widget.members.map((m) => m.generation).reduce((a, b) => a < b ? a : b);
    final generationOffset = minGeneration;
    
    print('世代标准化: 最小世代=$minGeneration, 位置偏移量=$generationOffset');
    
    // 找到根节点（没有父亲的成员）
    final roots = _findRoots(widget.members, children);
    print('找到根节点: ${roots.map((r) => r.name).join(', ')}');
    
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
    print('发现孤立成员: ${unprocessedMembers.map((m) => m.name).join(', ')}');
    
    for (final member in unprocessedMembers) {
      final memberX = currentX + nodeSpacing / 2;
      // 使用标准化的世代值计算位置：减去偏移量
      final normalizedGeneration = member.generation - generationOffset;
      final memberY = margin + normalizedGeneration * levelHeight;
      positions[member] = Offset(memberX, memberY);
      processedMembers.add(member);
      currentX += nodeSpacing * 2;
      print('放置孤立成员 ${member.name}: 位置(${memberX.toStringAsFixed(2)}, ${memberY.toStringAsFixed(2)}) [世代${member.generation}->标准化${normalizedGeneration}]');
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

    // 找到根节点（世代最小的成员）
    Member? root;
    if (widget.members.isNotEmpty) {
      root = widget.members.reduce((a, b) => a.generation < b.generation ? a : b);
    }

    _treeLayout = TreeLayout(
      positions: positions,
      children: children,
      spouses: spouses,
      root: root,
      width: maxX,
      height: maxY,
    );
    
    // 验证所有成员都被包含
    final missingMembers = widget.members.where((member) => !positions.containsKey(member)).toList();
    if (missingMembers.isNotEmpty) {
      print('警告: 以下成员没有被包含在布局中: ${missingMembers.map((m) => m.name).join(', ')}');
    }
    
    // 调试信息
    print('递归布局计算完成: ${positions.length} 个位置, ${children.length} 个父子关系, ${spouses.length} 个配偶关系');
    print('总成员数: ${widget.members.length}, 已布局成员数: ${positions.length}');
    print('画布大小: ${maxX} x ${maxY}');
    print('成员位置: ${positions.entries.map((e) => '${e.key.name}: (${e.value.dx}, ${e.value.dy})').join(', ')}');
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
  
  // 计算子树宽度（桌面版本算法）
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
    
    print('成员 ${member.name} 子树宽度: ${subtreeSizes[member]!.toStringAsFixed(2)} (子节点: ${childList.map((c) => c.name).join(', ')})');
  }
  
  // 放置节点（桌面版本算法）
  void _placeNode(Member member, Offset position, List<Member> members,
                 Map<Member, double> subtreeSizes, Map<Member, Offset> positions,
                 double nodeSpacing, double levelHeight, Set<Member> processedMembers, [int generationOffset = 0, double margin = 50.0]) {
    positions[member] = position;
    processedMembers.add(member);
    print('放置节点 ${member.name}: 位置(${position.dx.toStringAsFixed(2)}, ${position.dy.toStringAsFixed(2)})');
    
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



  void _selectMember(Member member) {
    setState(() {
      _selectedMember = _selectedMember?.id == member.id ? null : member;
    });
  }

  void _showMemberDetails(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('性别', member.gender == Gender.male ? '男' : 
                          member.gender == Gender.female ? '女' : '其他'),
            if (member.birthday != null)
              _buildDetailRow('出生', _formatDate(member.birthday!)),
            if (member.deathday != null)
              _buildDetailRow('去世', _formatDate(member.deathday!)),
            if (member.occupation != null && member.occupation!.isNotEmpty)
              _buildDetailRow('职业', member.occupation!),
            if (member.birthPlace != null && member.birthPlace!.isNotEmpty)
              _buildDetailRow('籍贯', member.birthPlace!),
            if (member.generation > 0)
              _buildDetailRow('世代', '第${member.generation}代'),
            if (member.ranking > 0)
              _buildDetailRow('排行', '第${member.ranking}位'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// 自定义绘制器用于绘制关系线
class _RelationshipPainter extends CustomPainter {
  final TreeLayout treeLayout;
  final Member? selectedMember;

  _RelationshipPainter({required this.treeLayout, this.selectedMember});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制父子关系 - 使用红色
    final parentChildPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 1.5 // 参考桌面应用的1.5像素线宽
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // 圆角线条

    for (final entry in treeLayout.children.entries) {
      final parent = entry.key;
      final children = entry.value;
      
      if (children.isNotEmpty && treeLayout.positions.containsKey(parent)) {
        final parentPos = treeLayout.positions[parent]!;
        
        for (final child in children) {
          if (treeLayout.positions.containsKey(child)) {
            final childPos = treeLayout.positions[child]!;
            _drawParentChildLine(canvas, parentChildPaint, parentPos, childPos);
          }
        }
      }
    }

    // 绘制配偶关系 - 使用粉色
    final spousePaint = Paint()
      ..color = const Color(0xFFE91E63)
      ..strokeWidth = 3.0 // 增加线条粗细
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // 圆角线条

    for (final entry in treeLayout.spouses.entries) {
      final member = entry.key;
      final spouses = entry.value;
      
      if (spouses.isNotEmpty && treeLayout.positions.containsKey(member)) {
        final memberPos = treeLayout.positions[member]!;
        
        for (final spouse in spouses) {
          if (treeLayout.positions.containsKey(spouse)) {
            final spousePos = treeLayout.positions[spouse]!;
            _drawSpouseLine(canvas, spousePaint, memberPos, spousePos);
          }
        }
      }
    }

    // 绘制选中成员的高亮效果
    if (selectedMember != null && treeLayout.positions.containsKey(selectedMember)) {
      _drawSelectedMemberHighlight(canvas, selectedMember!);
    }
  }

  // 绘制父子关系线
  void _drawParentChildLine(Canvas canvas, Paint paint, Offset parentPos, Offset childPos) {
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

  // 绘制配偶关系线
  void _drawSpouseLine(Canvas canvas, Paint paint, Offset pos1, Offset pos2) {
    final startPoint = Offset(pos1.dx + 30, pos1.dy);
    final endPoint = Offset(pos2.dx - 30, pos2.dy);
    
    canvas.drawLine(startPoint, endPoint, paint);
  }

  // 绘制选中成员的高亮效果
  void _drawSelectedMemberHighlight(Canvas canvas, Member selectedMember) {
    if (!treeLayout.positions.containsKey(selectedMember)) return;
    
    final position = treeLayout.positions[selectedMember]!;
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, 50, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}