import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_tree_provider.dart';
import '../models/family_tree.dart';
import '../models/member.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';
import 'family_tree_visualization_screen.dart';
import 'settings_screen.dart';

class FamilyTreeDetailScreen extends StatefulWidget {
  final FamilyTree familyTree;

  const FamilyTreeDetailScreen({super.key, required this.familyTree});

  @override
  State<FamilyTreeDetailScreen> createState() => _FamilyTreeDetailScreenState();
}

class _FamilyTreeDetailScreenState extends State<FamilyTreeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 监听标签页变化
    _tabController.addListener(() {
      setState(() {});
    });
    
    // 加载族谱成员
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyTreeProvider>().selectFamilyTree(widget.familyTree);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyTree.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: _tabController.index == 2 ? [] : [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMemberScreen(
                    familyTree: widget.familyTree,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动切换
        children: [
          _buildMembersTab(),
          _buildTreeVisualizationTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: '成员'),
            Tab(icon: Icon(Icons.account_tree), text: '族谱图'),
            Tab(icon: Icon(Icons.settings), text: '设置'),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return Consumer<FamilyTreeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.members.isEmpty) {
          return _buildEmptyMembersState();
        }

        return _buildMembersList(provider.members);
      },
    );
  }

  Widget _buildEmptyMembersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有成员',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角按钮添加第一个家族成员',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMemberScreen(
                    familyTree: widget.familyTree,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('添加成员'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List members) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<FamilyTreeProvider>().loadMembers(widget.familyTree.id);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          backgroundImage: member.photoPath != null 
              ? NetworkImage(member.photoPath!) 
              : null,
          child: member.photoPath == null
              ? Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          member.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  member.gender == Gender.male ? Icons.male : 
                  member.gender == Gender.female ? Icons.female : Icons.transgender,
                  size: 16,
                  color: member.gender == Gender.male ? const Color(0xFF1976D2) : 
                         member.gender == Gender.female ? const Color(0xFFD32F2F) : const Color(0xFF808080),
                ),
                const SizedBox(width: 4),
                Text(
                  member.gender == Gender.male ? '男' : 
                  member.gender == Gender.female ? '女' : '其他',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (member.generation > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '第${member.generation}代',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (member.birthday != null) ...[
              const SizedBox(height: 2),
              Text(
                '出生: ${_formatDate(member.birthday)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (member.occupation != null && member.occupation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '职业: ${member.occupation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMemberScreen(
                      familyTree: widget.familyTree,
                      member: member,
                    ),
                  ),
                );
                break;
              case 'delete':
                _deleteMember(member);
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
              builder: (context) => MemberDetailScreen(
                member: member,
                familyTree: widget.familyTree,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTreeVisualizationTab() {
    return Consumer<FamilyTreeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.members.isEmpty) {
          return _buildEmptyMembersState();
        }

        return FamilyTreeVisualizationScreen(
          familyTree: widget.familyTree,
          members: provider.members,
          relationships: provider.relationships,
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Consumer<FamilyTreeProvider>(
      builder: (context, provider, child) {
        return SettingsScreen(
          familyTree: widget.familyTree,
          members: provider.members,
          relationships: provider.relationships,
        );
      },
    );
  }


  void _deleteMember(member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确定要删除成员"${member.name}"吗？此操作不可撤销。'),
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
                  .deleteMember(member.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('成员删除成功')),
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
}

