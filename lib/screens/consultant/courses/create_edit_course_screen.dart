// lib/screens/consultant/courses/create_edit_course_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/training_course.dart';
import '../../../providers/managed_training_course_provider.dart';
import '../../../services/api_service.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final TrainingCourse? course;

  const CreateEditCourseScreen({super.key, this.course});

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.course != null;
  late final Map<String, dynamic> _courseData;
  bool _isLoading = false;

  // Controllers
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _trainerNameController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _courseData = {
      'Course Name': widget.course?.courseName ?? '',
      'Description': widget.course?.description ?? '',
      'Trainer Name': widget.course?.trainersName ?? '',
      'Skills': widget.course?.skills ?? '',
    };

    _courseNameController.text = _courseData['Course Name'];
    _descriptionController.text = _courseData['Description'];
    _trainerNameController.text = _courseData['Trainer Name'];
    _skillsController.text = _courseData['Skills'];
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _descriptionController.dispose();
    _trainerNameController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final provider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);
      try {
        if (_isEditing) {
          await provider.updateCourse(context, widget.course!.courseId!, _courseData);
        } else {
          await provider.createCourse(context, _courseData);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.message}'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل الدورة' : 'دورة تدريبية جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                controller: _courseNameController,
                label: 'اسم الدورة',
                icon: Icons.school_outlined,
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _courseData['Course Name'] = v!,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _trainerNameController,
                label: 'اسم المدرب',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _courseData['Trainer Name'] = v!,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'وصف الدورة',
                icon: Icons.description_outlined,
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _courseData['Description'] = v!,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _skillsController,
                label: 'المهارات المكتسبة (مفصولة بفاصلة)',
                icon: Icons.star_outline,
                onSaved: (v) => _courseData['Skills'] = v!,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(_isEditing ? Icons.save_alt_rounded : Icons.add_rounded),
                label: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء الدورة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}