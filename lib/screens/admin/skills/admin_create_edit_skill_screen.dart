// lib/screens/admin/skills/admin_create_edit_skill_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/skill.dart';
import '../../../providers/admin_skill_provider.dart';
import '../../../services/api_service.dart';

class AdminCreateEditSkillScreen extends StatefulWidget {
  final Skill? skill;

  const AdminCreateEditSkillScreen({super.key, this.skill});

  @override
  State<AdminCreateEditSkillScreen> createState() => _AdminCreateEditSkillScreenState();
}

class _AdminCreateEditSkillScreenState extends State<AdminCreateEditSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool get _isEditing => widget.skill != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.skill!.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<AdminSkillProvider>(context, listen: false);
      try {
        if (_isEditing) {
          await provider.updateSkill(context, widget.skill!.skillId!, _nameController.text);
        } else {
          await provider.createSkill(context, _nameController.text);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المهارة' : 'إضافة مهارة جديدة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المهارة'),
                validator: (value) => value!.isEmpty ? 'اسم المهارة مطلوب' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المهارة'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}