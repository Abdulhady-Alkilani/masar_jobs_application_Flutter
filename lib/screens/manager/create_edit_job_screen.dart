// lib/screens/manager/create_edit_job_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/job_opportunity.dart';
import '../../providers/managed_job_opportunity_provider.dart';
import '../../services/api_service.dart';

class CreateEditJobScreen extends StatefulWidget {
  final JobOpportunity? job;
  const CreateEditJobScreen({super.key, this.job});

  @override
  State<CreateEditJobScreen> createState() => _CreateEditJobScreenState();
}

class _CreateEditJobScreenState extends State<CreateEditJobScreen> {
  late Map<String, dynamic> _jobData;
  bool get _isEditing => widget.job != null;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _jobData = {
      'Job Title': job?.jobTitle ?? '',
      'Job Description': job?.jobDescription ?? '',
      'Qualification': job?.qualification ?? '',
      'Site': job?.site ?? '',
      'Skills': job?.skills ?? '',
      'Type': job?.type ?? 'وظيفة',
      'End Date': job?.endDate,
    };
  }

  // دالة لحساب نسبة اكتمال النموذج
  double _calculateProgress() {
    int totalFields = 5; // عدد الحقول الرئيسية
    int filledFields = 0;
    if (_jobData['Job Title'].isNotEmpty) filledFields++;
    if (_jobData['Job Description'].isNotEmpty) filledFields++;
    if (_jobData['Qualification'].isNotEmpty) filledFields++;
    if (_jobData['Site'].isNotEmpty) filledFields++;
    if (_jobData['Skills'].isNotEmpty) filledFields++;
    return filledFields / totalFields;
  }

  // دالة لفتح حوار التعديل
  Future<void> _showEditDialog(String fieldKey, String title, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) async {
    final controller = TextEditingController(text: _jobData[fieldKey]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $title'),
        content: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('حفظ')),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _jobData[fieldKey] = result;
      });
    }
  }

  // دالة اختيار التاريخ
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _jobData['End Date'] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _jobData['End Date'] = picked);
    }
  }

  // دالة الحفظ النهائية
  Future<void> _submitForm() async {
    // ... نفس كود الحفظ السابق ...
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل فرصة العمل' : 'فرصة عمل جديدة'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: AnimatedContainer(
            duration: 500.ms,
            height: 4.0,
            width: MediaQuery.of(context).size.width * progress,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitForm,
        label: Text(_isEditing ? 'حفظ التعديلات' : 'نشر فرصة العمل'),
        icon: Icon(_isEditing ? Icons.save_alt_rounded : Icons.publish_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard(
            icon: Icons.title_rounded,
            title: 'المسمى الوظيفي',
            value: _jobData['Job Title'],
            placeholder: 'مثال: مطور تطبيقات Flutter',
            onTap: () => _showEditDialog('Job Title', 'المسمى الوظيفي'),
          ).animate().fadeIn(delay: 200.ms),

          _buildInfoCard(
            icon: Icons.description_outlined,
            title: 'الوصف الوظيفي',
            value: _jobData['Job Description'],
            placeholder: 'وصف المهام والمسؤوليات...',
            onTap: () => _showEditDialog('Job Description', 'الوصف الوظيفي', maxLines: 5),
          ).animate().fadeIn(delay: 300.ms),

          _buildInfoCard(
            icon: Icons.school_outlined,
            title: 'المؤهلات المطلوبة',
            value: _jobData['Qualification'],
            placeholder: 'مثال: بكالوريوس حاسب آلي...',
            onTap: () => _showEditDialog('Qualification', 'المؤهلات المطلوبة', maxLines: 3),
          ).animate().fadeIn(delay: 400.ms),

          _buildInfoCard(
            icon: Icons.star_outline_rounded,
            title: 'المهارات (مفصولة بفاصلة)',
            value: _jobData['Skills'],
            placeholder: 'مثال: Dart, Firebase, Git',
            onTap: () => _showEditDialog('Skills', 'المهارات'),
          ).animate().fadeIn(delay: 500.ms),

          _buildInfoCard(
            icon: Icons.location_on_outlined,
            title: 'الموقع',
            value: _jobData['Site'],
            placeholder: 'مثال: الرياض، عن بعد',
            onTap: () => _showEditDialog('Site', 'الموقع'),
          ).animate().fadeIn(delay: 600.ms),

          _buildDateCard(
            icon: Icons.event_busy_outlined,
            title: 'تاريخ انتهاء التقديم',
            date: _jobData['End Date'],
            onTap: _selectEndDate,
          ).animate().fadeIn(delay: 700.ms),

          _buildDropdownCard(
            icon: Icons.category_outlined,
            title: 'نوع الفرصة',
            currentValue: _jobData['Type'],
            items: ['وظيفة', 'تدريب'],
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _jobData['Type'] = newValue);
              }
            },
          ).animate().fadeIn(delay: 800.ms),

        ],
      ),
    );
  }

  // --- ويدجتس البطاقات التفاعلية ---
  Widget _buildInfoCard({required IconData icon, required String title, required String value, required String placeholder, required VoidCallback onTap}) {
    final bool hasValue = value.isNotEmpty;
    return Card(
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

  Widget _buildDateCard({required IconData icon, required String title, DateTime? date, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          date != null ? DateFormat('dd MMMM yyyy', 'ar').format(date) : 'اضغط للاختيار',
          style: TextStyle(color: date != null ? Colors.black87 : Colors.grey),
        ),
        trailing: const Icon(Icons.edit_calendar_outlined, color: Colors.grey, size: 20),
      ),
    );
  }

  Widget _buildDropdownCard({required IconData icon, required String title, required String currentValue, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_rounded),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}