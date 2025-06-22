// lib/screens/admin/groups/admin_create_edit_group_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/group.dart';
import '../../../providers/admin_group_provider.dart';
import '../../../services/api_service.dart';

class AdminCreateEditGroupScreen extends StatefulWidget {
  final Group? group;

  const AdminCreateEditGroupScreen({super.key, this.group});

  @override
  State<AdminCreateEditGroupScreen> createState() => _AdminCreateEditGroupScreenState();
}

class _AdminCreateEditGroupScreenState extends State<AdminCreateEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _linkController.text = widget.group!.telegramHyperLink!;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<AdminGroupProvider>(context, listen: false);
      try {
        if (_isEditing) {
          await provider.updateGroup(context, widget.group!.groupId!, _linkController.text);
        } else {
          await provider.createGroup(context, _linkController.text);
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
        title: Text(_isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'رابط تليجرام'),
                keyboardType: TextInputType.url,
                validator: (value) => value!.isEmpty ? 'الرابط مطلوب' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة المجموعة'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}