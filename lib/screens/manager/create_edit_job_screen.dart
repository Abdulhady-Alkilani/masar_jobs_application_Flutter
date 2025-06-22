// lib/screens/manager/create_edit_job_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/managed_job_opportunity_provider.dart';
import '../../models/job_opportunity.dart';
import '../../services/api_service.dart';

class CreateEditJobScreen extends StatefulWidget {
  final JobOpportunity? job; // إذا كان null، فهذا يعني إنشاء جديد

  const CreateEditJobScreen({super.key, this.job});

  @override
  State<CreateEditJobScreen> createState() => _CreateEditJobScreenState();
}

class _CreateEditJobScreenState extends State<CreateEditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _jobData;
  bool get _isEditing => widget.job != null;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _qualificationController;
  late TextEditingController _siteController;
  late TextEditingController _skillsController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    // تهيئة البيانات
    _jobData = {
      'Job Title': job?.jobTitle ?? '',
      'Job Description': job?.jobDescription ?? '',
      'Qualification': job?.qualification ?? '',
      'Site': job?.site ?? '',
      'Skills': job?.skills ?? '',
      'Type': job?.type ?? 'وظيفة',
      'Status': job?.status ?? 'مفعل',
      'End Date': job?.endDate,
    };

    // تهيئة الـ Controllers
    _titleController = TextEditingController(text: _jobData['Job Title']);
    _descriptionController = TextEditingController(text: _jobData['Job Description']);
    _qualificationController = TextEditingController(text: _jobData['Qualification']);
    _siteController = TextEditingController(text: _jobData['Site']);
    _skillsController = TextEditingController(text: _jobData['Skills']);
    _endDateController = TextEditingController(
      text: _jobData['End Date'] != null
          ? DateFormat('yyyy-MM-dd').format(_jobData['End Date'])
          : '',
    );
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _jobData['End Date'] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _jobData['End Date']) {
      setState(() {
        _jobData['End Date'] = picked;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<ManagedJobOpportunityProvider>(context, listen: false);

      // تحويل التاريخ إلى الصيغة الصحيحة قبل الإرسال
      if (_jobData['End Date'] != null) {
        _jobData['End Date'] = (_jobData['End Date'] as DateTime).toIso8601String();
      }

      try {
        if (_isEditing) {
          await provider.updateJob(context, widget.job!.jobId!, _jobData);
        } else {
          await provider.createJob(context, _jobData);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green),
        );
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
    _qualificationController.dispose();
    _siteController.dispose();
    _skillsController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل فرصة العمل' : 'إنشاء فرصة عمل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'المسمى الوظيفي'),
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                onSaved: (v) => _jobData['Job Title'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف الوظيفي'),
                maxLines: 5,
                onSaved: (v) => _jobData['Job Description'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: 'المؤهلات المطلوبة'),
                onSaved: (v) => _jobData['Qualification'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _siteController,
                decoration: const InputDecoration(labelText: 'الموقع (مثال: عن بعد, الرياض)'),
                onSaved: (v) => _jobData['Site'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(labelText: 'المهارات (مفصولة بفاصلة)'),
                onSaved: (v) => _jobData['Skills'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  labelText: 'تاريخ انتهاء التقديم',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectEndDate(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _jobData['Type'],
                decoration: const InputDecoration(labelText: 'النوع'),
                items: ['وظيفة', 'تدريب'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _jobData['Type'] = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(_isEditing ? 'حفظ التعديلات' : 'نشر فرصة العمل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}