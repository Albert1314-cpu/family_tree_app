import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/family_tree_provider.dart';
import '../models/family_tree.dart';
import '../models/member.dart';

class AddMemberScreen extends StatefulWidget {
  final FamilyTree familyTree;
  final Member? member;

  const AddMemberScreen({
    super.key,
    required this.familyTree,
    this.member,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _occupationController = TextEditingController();
  final _notesController = TextEditingController();
  final _spouseNameController = TextEditingController();

  String _selectedGender = 'male';
  DateTime? _birthday;
  DateTime? _deathday;
  String? _photoPath;
  int _generation = 0;
  int _ranking = 0;
  Member? _selectedFather;
  Member? _selectedMother;

  bool get isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final member = widget.member!;
      _nameController.text = member.name;
      _selectedGender = member.gender == Gender.male ? 'male' : 
                       member.gender == Gender.female ? 'female' : 'other';
      _birthday = member.birthday;
      _deathday = member.deathday;
      _birthPlaceController.text = member.birthPlace ?? '';
      _occupationController.text = member.occupation ?? '';
      _notesController.text = member.notes ?? '';
      _spouseNameController.text = member.spouseName ?? '';
      _photoPath = member.photoPath;
      _generation = member.generation;
      _ranking = member.ranking;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _occupationController.dispose();
    _notesController.dispose();
    _spouseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑成员' : '添加成员'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMember,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 头像选择
              _buildPhotoSection(),
              const SizedBox(height: 24),
              
              // 基本信息
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              
              // 详细信息
              _buildDetailInfoSection(),
              const SizedBox(height: 24),
              
              // 世代信息
              _buildGenerationSection(),
              const SizedBox(height: 24),
              
              // 关系信息
              _buildRelationshipSection(),
              const SizedBox(height: 24),
              
              // 操作按钮
              if (!isEditing) ...[
                ElevatedButton.icon(
                  onPressed: _createMember,
                  icon: const Icon(Icons.add),
                  label: const Text('添加成员'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
              if (isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('取消'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveMember,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '头像',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: _photoPath != null 
                    ? FileImage(File(_photoPath!)) 
                    : null,
                child: _photoPath == null
                    ? Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击选择头像',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名 *',
                hintText: '请输入姓名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: '性别 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('男')),
                DropdownMenuItem(value: 'female', child: Text('女')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectBirthday,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '出生日期',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      child: Text(
                        _birthday != null 
                            ? '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                            : '选择出生日期',
                        style: TextStyle(
                          color: _birthday != null 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDeathday,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '去世日期',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        _deathday != null 
                            ? '${_deathday!.year}-${_deathday!.month.toString().padLeft(2, '0')}-${_deathday!.day.toString().padLeft(2, '0')}'
                            : '选择去世日期',
                        style: TextStyle(
                          color: _deathday != null 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoSection() {
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
            TextFormField(
              controller: _birthPlaceController,
              decoration: const InputDecoration(
                labelText: '籍贯',
                hintText: '请输入籍贯',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _occupationController,
              decoration: const InputDecoration(
                labelText: '职业',
                hintText: '请输入职业',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _spouseNameController,
              decoration: const InputDecoration(
                labelText: '配偶姓名',
                hintText: '请输入配偶姓名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '请输入备注信息',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '世代信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _generation.toString()),
                    decoration: InputDecoration(
                      labelText: '世代',
                      hintText: '0',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.timeline),
                      suffixIcon: _selectedFather != null 
                          ? Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            )
                          : null,
                      helperText: _selectedFather != null 
                          ? '已自动设置为第${_generation}代（${_selectedFather!.name}的下一代）'
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _generation = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _ranking.toString()),
                    decoration: const InputDecoration(
                      labelText: '排行',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _ranking = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  Future<void> _selectDeathday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deathday ?? DateTime.now(),
      firstDate: _birthday ?? DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _deathday = picked;
      });
    }
  }

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FamilyTreeProvider>();
    final newMemberId = await provider.createMember(
      name: _nameController.text.trim(),
      familyTreeId: widget.familyTree.id,
      gender: _selectedGender,
      birthday: _birthday,
      deathday: _deathday,
      birthPlace: _birthPlaceController.text.trim().isEmpty 
          ? null 
          : _birthPlaceController.text.trim(),
      occupation: _occupationController.text.trim().isEmpty 
          ? null 
          : _occupationController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      photoPath: _photoPath,
      generation: _generation,
      ranking: _ranking,
      spouseName: _spouseNameController.text.trim().isEmpty 
          ? null 
          : _spouseNameController.text.trim(),
    );

    if (newMemberId != null && mounted) {
      // 创建父子关系
      if (_selectedFather != null) {
        await provider.createParentChildRelationship(_selectedFather!.id, newMemberId);
      }
      
      if (_selectedMother != null) {
        await provider.createParentChildRelationship(_selectedMother!.id, newMemberId);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('成员添加成功')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '添加失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FamilyTreeProvider>();
    final updatedMember = widget.member!.copyWith(
      name: _nameController.text.trim(),
      gender: _selectedGender == 'male' ? Gender.male : 
              _selectedGender == 'female' ? Gender.female : Gender.other,
      birthday: _birthday,
      deathday: _deathday,
      birthPlace: _birthPlaceController.text.trim().isEmpty 
          ? null 
          : _birthPlaceController.text.trim(),
      occupation: _occupationController.text.trim().isEmpty 
          ? null 
          : _occupationController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      photoPath: _photoPath,
      generation: _generation,
      ranking: _ranking,
      spouseName: _spouseNameController.text.trim().isEmpty 
          ? null 
          : _spouseNameController.text.trim(),
    );

    final success = await provider.updateMember(updatedMember);

    if (success && mounted) {
      // 更新父子关系
      await _updateParentChildRelationships(provider);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('成员更新成功')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '更新失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateParentChildRelationships(FamilyTreeProvider provider) async {
    final memberId = widget.member!.id;
    
    // 删除现有的父子关系
    await provider.deleteRelationshipsByMemberId(memberId);
    
    // 创建新的父子关系
    if (_selectedFather != null) {
      await provider.createParentChildRelationship(_selectedFather!.id, memberId);
    }
    
    if (_selectedMother != null) {
      await provider.createParentChildRelationship(_selectedMother!.id, memberId);
    }
  }

  Widget _buildRelationshipSection() {
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectFather,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '父亲',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.man),
                      ),
                      child: Text(
                        _selectedFather?.name ?? '选择父亲',
                        style: TextStyle(
                          color: _selectedFather != null 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectMother,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '母亲',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.woman),
                      ),
                      child: Text(
                        _selectedMother?.name ?? '选择母亲',
                        style: TextStyle(
                          color: _selectedMother != null 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedFather != null || _selectedMother != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedFather != null)
                    Chip(
                      label: Text('父亲: ${_selectedFather!.name}'),
                      onDeleted: () {
                        setState(() {
                          _selectedFather = null;
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                  if (_selectedMother != null)
                    Chip(
                      label: Text('母亲: ${_selectedMother!.name}'),
                      onDeleted: () {
                        setState(() {
                          _selectedMother = null;
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectFather() async {
    final provider = context.read<FamilyTreeProvider>();
    final availableMembers = provider.members
        .where((member) => member.gender == Gender.male)
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可选的男性成员')),
      );
      return;
    }

    final selectedMember = await showDialog<Member>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择父亲'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableMembers.length,
            itemBuilder: (context, index) {
              final member = availableMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text('第${member.generation}代'),
                onTap: () => Navigator.pop(context, member),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedMember != null) {
      setState(() {
        _selectedFather = selectedMember;
        // 自动设置后代数为父亲的下一代
        _generation = selectedMember.generation + 1;
      });
    }
  }

  Future<void> _selectMother() async {
    final provider = context.read<FamilyTreeProvider>();
    final availableMembers = provider.members
        .where((member) => member.gender == Gender.female)
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可选的女性成员')),
      );
      return;
    }

    final selectedMember = await showDialog<Member>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择母亲'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableMembers.length,
            itemBuilder: (context, index) {
              final member = availableMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : 'F',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text('第${member.generation}代'),
                onTap: () => Navigator.pop(context, member),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedMember != null) {
      setState(() {
        _selectedMother = selectedMember;
      });
    }
  }
}

