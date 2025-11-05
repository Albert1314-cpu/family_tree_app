import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_tree_provider.dart';
import '../models/family_tree.dart';

class CreateFamilyTreeScreen extends StatefulWidget {
  final FamilyTree? familyTree;

  const CreateFamilyTreeScreen({super.key, this.familyTree});

  @override
  State<CreateFamilyTreeScreen> createState() => _CreateFamilyTreeScreenState();
}

class _CreateFamilyTreeScreenState extends State<CreateFamilyTreeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _notesController = TextEditingController();

  bool get isEditing => widget.familyTree != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.familyTree!.name;
      _surnameController.text = widget.familyTree!.surname ?? '';
      _notesController.text = widget.familyTree!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑族谱' : '新建族谱'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveFamilyTree,
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
              Card(
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
                          labelText: '族谱名称 *',
                          hintText: '请输入族谱名称',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入族谱名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _surnameController,
                        decoration: const InputDecoration(
                          labelText: '姓氏',
                          hintText: '请输入主要姓氏',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: '备注',
                          hintText: '请输入族谱备注信息',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!isEditing) ...[
                ElevatedButton.icon(
                  onPressed: _createFamilyTree,
                  icon: const Icon(Icons.add),
                  label: const Text('创建族谱'),
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
                        onPressed: _saveFamilyTree,
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

  Future<void> _createFamilyTree() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FamilyTreeProvider>();
    final success = await provider.createFamilyTree(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim().isEmpty 
          ? null 
          : _surnameController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('族谱创建成功')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '创建失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveFamilyTree() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FamilyTreeProvider>();
    final updatedFamilyTree = widget.familyTree!.copyWith(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim().isEmpty 
          ? null 
          : _surnameController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    final success = await provider.updateFamilyTree(updatedFamilyTree);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('族谱更新成功')),
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
}


