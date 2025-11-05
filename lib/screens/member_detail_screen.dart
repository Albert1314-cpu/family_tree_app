import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_tree_provider.dart';
import '../models/family_tree.dart';
import '../models/member.dart';
import 'add_member_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  final Member member;
  final FamilyTree familyTree;

  const MemberDetailScreen({
    super.key,
    required this.member,
    required this.familyTree,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMemberScreen(
                    familyTree: familyTree,
                    member: member,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像和基本信息
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            
            // 详细信息
            _buildDetailCard(context),
            const SizedBox(height: 16),
            
            // 关系信息
            _buildRelationsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: member.photoPath != null 
                  ? NetworkImage(member.photoPath!) 
                  : null,
              child: member.photoPath == null
                  ? Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        member.gender.name == 'male' ? Icons.male : 
                        member.gender.name == 'female' ? Icons.female : Icons.transgender,
                        size: 20,
                        color: member.gender.name == 'male' ? const Color(0xFF1976D2) : 
                               member.gender.name == 'female' ? const Color(0xFFD32F2F) : const Color(0xFF808080),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.gender.name == 'male' ? '男' : 
                        member.gender.name == 'female' ? '女' : '其他',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  if (member.age != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${member.age}岁',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (member.birthday != null)
              _buildInfoRow(context, '出生日期', _formatDate(member.birthday!)),
            if (member.deathday != null)
              _buildInfoRow(context, '去世日期', _formatDate(member.deathday!)),
            if (member.birthPlace != null && member.birthPlace!.isNotEmpty)
              _buildInfoRow(context, '籍贯', member.birthPlace!),
            if (member.occupation != null && member.occupation!.isNotEmpty)
              _buildInfoRow(context, '职业', member.occupation!),
            if (member.spouseName != null && member.spouseName!.isNotEmpty)
              _buildInfoRow(context, '配偶', member.spouseName!),
            if (member.generation > 0)
              _buildInfoRow(context, '世代', '第${member.generation}代'),
            if (member.ranking > 0)
              _buildInfoRow(context, '排行', '第${member.ranking}位'),
            if (member.notes != null && member.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '备注',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                member.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelationsCard(BuildContext context) {
    return Consumer<FamilyTreeProvider>(
      builder: (context, provider, child) {
        final parents = provider.getParents(member.id);
        final children = provider.getChildren(member.id);
        final spouses = provider.getSpouses(member.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '家庭关系',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 父母
                if (parents.isNotEmpty) ...[
                  _buildRelationSection(context, '父母', parents),
                  const SizedBox(height: 16),
                ],
                
                // 配偶
                if (spouses.isNotEmpty) ...[
                  _buildRelationSection(context, '配偶', spouses),
                  const SizedBox(height: 16),
                ],
                
                // 子女
                if (children.isNotEmpty) ...[
                  _buildRelationSection(context, '子女', children),
                ],
                
                if (parents.isEmpty && spouses.isEmpty && children.isEmpty) ...[
                  Text(
                    '暂无家庭关系信息',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationSection(BuildContext context, String title, List<Member> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...members.map((member) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (member.age != null)
                Text(
                  '${member.age}岁',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

