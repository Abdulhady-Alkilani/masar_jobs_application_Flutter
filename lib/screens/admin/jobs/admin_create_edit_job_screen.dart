// lib/screens/admin/jobs/admin_create_edit_job_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_opportunity.dart';
import '../../../models/user.dart';
import '../../../providers/admin_job_provider.dart';
import '../../../providers/admin_user_provider.dart'; // لجلب المدراء
import '../../../services/api_service.dart';

class AdminCreateEditJobScreen extends StatefulWidget {
  final JobOpportunity? job;

  const AdminCreateEditJobScreen({super.key, this.job});

  @override
  State<AdminCreateEditJobScreen> createState() => _AdminCreateEditJobScreenState();
}

class _AdminCreateEditJobScreenState extends State<AdminCreateEditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.job != null;
  late Map<String, dynamic> _jobData;
  bool _isLoadingUsers = true;
  List<User> _jobPosters = []; // مدراء الشركات والاستشاريون

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _siteController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jobData = {
      'Job Title': widget.job?.jobTitle ?? '',
      'Job Description': widget.job?.jobDescription ?? '',
      'Qualification': widget.job?.qualification ?? '',
      'Site': widget.job?.site ?? '',
      'Skills': widget.job?.skills ?? '',
      'Type': widget.job?.type ?? 'وظيفة',
      'Status': widget.job?.status ?? 'مفعل',
      'UserID': widget.job?.userId,
    };

    _titleController.text = _jobData['Job Title'];
    _descriptionController.text = _jobData['Job Description'];
    _qualificationController.text = _jobData['Qualification'];
    _siteController.text = _jobData['Site'];
    _skillsController.text = _jobData['Skills'];

    _fetchJobPosters();
  }

  Future<void> _fetchJobPosters() async {
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
    // تأكد من جلب جميع المستخدمين أو وجودهم مسبقًا
    if (userProvider.users.isEmpty) {
      await userProvider.fetchAllUsers(context);
    }
    if (mounted) {
      setState(() {
        _jobPosters = userProvider.users
            .where((user) => user.type == 'مدير شركة' || user.type == 'خبير استشاري')
            .toList();
        _isLoadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    // ... dispose all controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _qualificationController.dispose();
    _siteController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_jobData['UserID'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار ناشر للوظيفة')));
        return;
      }
      _formKey.currentState!.save();
      final provider = Provider.of<AdminJobProvider>(context, listen: false);
      try {
        if (_isEditing) {
          await provider.updateJob(context, widget.job!.jobId!, _jobData);
        } else {
          await provider.createJob(context, _jobData);
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
        title: Text(_isEditing ? 'تعديل وظيفة' : 'إنشاء وظيفة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'المسمى الوظيفي'), validator: (v) => v!.isEmpty ? 'مطلوب' : null, onSaved: (v) => _jobData['Job Title'] = v!),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'الوصف الوظيفي'), maxLines: 4, onSaved: (v) => _jobData['Job Description'] = v!),
              TextFormField(controller: _qualificationController, decoration: const InputDecoration(labelText: 'المؤهلات'), onSaved: (v) => _jobData['Qualification'] = v!),
              TextFormField(controller: _siteController, decoration: const InputDecoration(labelText: 'الموقع'), onSaved: (v) => _jobData['Site'] = v!),
              TextFormField(controller: _skillsController, decoration: const InputDecoration(labelText: 'المهارات (مفصولة بفاصلة)'), onSaved: (v) => _jobData['Skills'] = v!),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _jobData['Type'],
                decoration: const InputDecoration(labelText: 'النوع'),
                items: ['وظيفة', 'تدريب'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _jobData['Type'] = v!),
              ),

              const SizedBox(height: 16),
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                value: _jobData['UserID'],
                hint: const Text('اختر الناشر'),
                decoration: const InputDecoration(labelText: 'الناشر'),
                items: _jobPosters.map((User user) => DropdownMenuItem<int>(value: user.userId, child: Text('${user.firstName} ${user.lastName}'))).toList(),
                onChanged: (v) => setState(() => _jobData['UserID'] = v),
                validator: (v) => v == null ? 'مطلوب' : null,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء الوظيفة'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}