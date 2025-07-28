// lib/screens/manager/create_edit_course_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/training_course.dart';
import '../../providers/managed_training_course_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/rive_loading_indicator.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final TrainingCourse? course;
  const CreateEditCourseScreen({super.key, this.course});

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  late Map<String, dynamic> _courseData;
  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _courseData = {
      'Course name': course?.courseName ?? '',
      'Trainers name': course?.trainersName ?? '',
      'Course Description': course?.description ?? '',
      'Site': course?.site ?? '',
      'Skills': course?.skills ?? '',
      'Stage': course?.stage ?? 'مبتدئ',
      'Start Date': course?.startDate,
      'End Date': course?.endDate,
    };
  }

  // دالة لحساب نسبة اكتمال النموذج
  double _calculateProgress() {
    int totalFields = 6; // عدد الحقول الرئيسية
    int filledFields = 0;
    if (_courseData['Course name'].isNotEmpty) filledFields++;
    if (_courseData['Trainers name'].isNotEmpty) filledFields++;
    if (_courseData['Course Description'].isNotEmpty) filledFields++;
    if (_courseData['Site'].isNotEmpty) filledFields++;
    if (_courseData['Skills'].isNotEmpty) filledFields++;
    if (_courseData['Start Date'] != null) filledFields++;
    return filledFields / totalFields;
  }

  // دالة لفتح حوار التعديل
  Future<void> _showEditDialog(String fieldKey, String title, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) async {
    final controller = TextEditingController(text: _courseData[fieldKey]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $title'),
        content: TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != null) setState(() => _courseData[fieldKey] = result);
  }

  // دالة اختيار التواريخ
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _courseData['Start Date'] ?? DateTime.now(),
        end: _courseData['End Date'] ?? DateTime.now().add(const Duration(days: 7)),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _courseData['Start Date'] = picked.start;
        _courseData['End Date'] = picked.end;
      });
    }
  }

  // دالة الحفظ النهائية
  Future<void> _submitForm() async {
    final provider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);

    // تحويل التواريخ قبل الإرسال
    _courseData['Start Date'] = (_courseData['Start Date'] as DateTime?)?.toIso8601String();
    _courseData['End Date'] = (_courseData['End Date'] as DateTime?)?.toIso8601String();

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل العملية: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل الدورة' : 'دورة تدريبية جديدة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: AnimatedContainer(
            duration: 500.ms,
            height: 4.0,
            width: MediaQuery.of(context).size.width * progress,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitForm,
        label: Text(_isEditing ? 'حفظ التعديلات' : 'نشر الدورة'),
        icon: Icon(_isEditing ? Icons.save_alt_rounded : Icons.publish_rounded),
      ),
      body: Consumer<ManagedTrainingCourseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: RiveLoadingIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoCard(
                icon: Icons.school_outlined,
                title: 'عنوان الدورة',
                value: _courseData['Course name'],
                placeholder: 'مثال: مقدمة في Flutter',
                onTap: () => _showEditDialog('Course name', 'عنوان الدورة'),
              ),
              _buildInfoCard(
                icon: Icons.person_outline,
                title: 'اسم المدرب',
                value: _courseData['Trainers name'],
                placeholder: 'مثال: د. أحمد خالد',
                onTap: () => _showEditDialog('Trainers name', 'اسم المدرب'),
              ),
              _buildInfoCard(
                icon: Icons.description_outlined,
                title: 'وصف الدورة',
                value: _courseData['Course Description'],
                placeholder: 'وصف محتوى الدورة وأهدافها...',
                onTap: () => _showEditDialog('Course Description', 'وصف الدورة', maxLines: 5),
              ),
              _buildInfoCard(
                icon: Icons.star_border_rounded,
                title: 'المهارات المكتسبة (مفصولة بفاصلة)',
                value: _courseData['Skills'],
                placeholder: 'مثال: Dart, State Management',
                onTap: () => _showEditDialog('Skills', 'المهارات'),
              ),
              _buildDateRangeCard(
                icon: Icons.date_range_outlined,
                title: 'تاريخ بدء وانتهاء الدورة',
                startDate: _courseData['Start Date'],
                endDate: _courseData['End Date'],
                onTap: _selectDateRange,
              ),
              _buildDropdownCard(
                title: 'المستوى',
                currentValue: _courseData['Stage'],
                items: ['مبتدئ', 'متوسط', 'متقدم'],
                onChanged: (newValue) {
                  if (newValue != null) setState(() => _courseData['Stage'] = newValue);
                },
              ),
            ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required String placeholder, required VoidCallback onTap}) {
    final bool hasValue = value.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          hasValue ? value : placeholder,
          style: TextStyle(color: hasValue ? Colors.black87 : Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
      ),
    );
  }

  Widget _buildDateRangeCard({required IconData icon, required String title, DateTime? startDate, DateTime? endDate, required VoidCallback onTap}) {
    String dateText = 'اضغط للاختيار';
    if (startDate != null && endDate != null) {
      dateText = '${DateFormat('d/M/y', 'ar').format(startDate)} - ${DateFormat('d/M/y', 'ar').format(endDate)}';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dateText, style: TextStyle(color: startDate != null ? Colors.black87 : Colors.grey)),
        trailing: const Icon(Icons.edit_calendar_outlined, color: Colors.grey, size: 20),
      ),
    );
  }

  Widget _buildDropdownCard({required String title, required String currentValue, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            hint: Text(title),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}