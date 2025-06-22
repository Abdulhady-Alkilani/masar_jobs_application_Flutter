// lib/screens/manager/create_edit_course_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/managed_training_course_provider.dart';
import '../../models/training_course.dart';
import '../../services/api_service.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final TrainingCourse? course; // إذا كان null، فهذا يعني إنشاء جديد

  const CreateEditCourseScreen({super.key, this.course});

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _courseData;
  bool get _isEditing => widget.course != null;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _siteController;
  late TextEditingController _hoursController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();

    // تهيئة البيانات
    _courseData = {
      'Title': widget.course?.site ?? '',
      'Description': widget.course?.description ?? '',
      'Site': widget.course?.site ?? '',
      'Hours': widget.course?.hours?.toString() ?? '',
      'Status': widget.course?.status ?? 'مفعل',
      'Date': widget.course?.site,
    };

    // تهيئة الـ Controllers
    _titleController = TextEditingController(text: _courseData['Title']);
    _descriptionController = TextEditingController(text: _courseData['Description']);
    _siteController = TextEditingController(text: _courseData['Site']);
    _hoursController = TextEditingController(text: _courseData['Hours']);
    _dateController = TextEditingController(
      text: _courseData['Date'] != null
          ? DateFormat('yyyy-MM-dd').format(_courseData['Date'])
          : '',
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _courseData['Date'] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _courseData['Date']) {
      setState(() {
        _courseData['Date'] = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);

      // تحويل التاريخ إلى صيغة ISO 8601
      if (_courseData['Date'] != null) {
        _courseData['Date'] = (_courseData['Date'] as DateTime).toIso8601String();
      }

      // تحويل عدد الساعات إلى int
      if (_courseData['Hours'] != null && _courseData['Hours'].isNotEmpty) {
        _courseData['Hours'] = int.tryParse(_courseData['Hours']);
      } else {
        _courseData.remove('Hours'); // إزالته إذا كان فارغًا
      }

      try {
        if (_isEditing) {
          await provider.updateCourse(context, widget.course!.courseId!, _courseData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الدورة بنجاح'), backgroundColor: Colors.green),
          );
        } else {
          await provider.createCourse(context, _courseData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الدورة بنجاح'), backgroundColor: Colors.green),
          );
        }
        Navigator.pop(context);
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل العملية: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _siteController.dispose();
    _hoursController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ManagedTrainingCourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل الدورة التدريبية' : 'إنشاء دورة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان الدورة'),
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _courseData['Title'] = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف الدورة'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _courseData['Description'] = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _siteController,
                decoration: const InputDecoration(labelText: 'الموقع'),
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _courseData['Site'] = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'عدد الساعات'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _courseData['Hours'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'تاريخ بدء الدورة',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _courseData['Status'],
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: ['مفعل', 'معلق', 'محذوف'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _courseData['Status'] = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء الدورة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}