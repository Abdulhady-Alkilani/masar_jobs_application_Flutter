import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_job_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../models/job_opportunity.dart';
import '../services/api_service.dart'; // تأكد من المسار
// قد تحتاج لاستيراد provider للمستخدمين لاختيار الناشر (Company Manager / Admin)

class CreateEditJobScreen extends StatefulWidget {
  final JobOpportunity? job; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const CreateEditJobScreen({Key? key, this.job}) : super(key: key);

  @override
  _CreateEditJobScreenState createState() => _CreateEditJobScreenState();
}

class _CreateEditJobScreenState extends State<CreateEditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController(); // لتعيين الناشر (لـ Admin)
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // تاريخ النشر
  final TextEditingController _skillsController = TextEditingController(); // كنص أو JSON
  final TextEditingController _typeController = TextEditingController(); // أو Dropdown (وظيفة/تدريب)
  final TextEditingController _endDateController = TextEditingController(); // تاريخ الانتهاء
  final TextEditingController _statusController = TextEditingController(); // أو Dropdown (مفعل/معلق/محذوف)

  DateTime? _selectedDate;
  DateTime? _selectedEndDate;


  bool get isEditing => widget.job != null;

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقول بالبيانات الحالية للوظيفة
    if (isEditing) {
      _userIdController.text = widget.job!.userId?.toString() ?? '';
      _jobTitleController.text = widget.job!.jobTitle ?? '';
      _jobDescriptionController.text = widget.job!.jobDescription ?? '';
      _qualificationController.text = widget.job!.qualification ?? '';
      _siteController.text = widget.job!.site ?? '';
      _selectedDate = widget.job!.date;
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
      _skillsController.text = widget.job!.skills ?? '';
      _typeController.text = widget.job!.type ?? '';
      _selectedEndDate = widget.job!.endDate;
      _endDateController.text = _selectedEndDate?.toString().split(' ')[0] ?? '';
      _statusController.text = widget.job!.status ?? '';
    } else {
      // في حالة الإضافة، يمكن تعيين تاريخ النشر الافتراضي للتاريخ الحالي
      _selectedDate = DateTime.now();
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
    }

    // TODO: إذا كنت ستستخدم Dropdown لأنواع محددة (Type, Status) أو لاختيار الناشر (UserID)، قم بتهيئة الخيارات
  }

  // تابع لاختيار تاريخ النشر
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  // تابع لاختيار تاريخ الانتهاء
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedDate ?? DateTime.now(),
      firstDate: _selectedDate ?? DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = picked.toString().split(' ')[0];
      });
    }
  }


  // تابع لحفظ (إنشاء أو تعديل) فرصة العمل
  Future<void> _saveJob() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminJobProvider>(context, listen: false);

      final jobData = {
        'UserID': int.tryParse(_userIdController.text), // تحويل النص إلى عدد صحيح
        'Job Title': _jobTitleController.text,
        'Job Description': _jobDescriptionController.text,
        'Qualification': _qualificationController.text,
        'Site': _siteController.text,
        'Date': _selectedDate?.toIso8601String().split('T')[0],
        'Skills': _skillsController.text, // كنص
        'Type': _typeController.text,
        'End Date': _selectedEndDate?.toIso8601String().split('T')[0],
        'Status': _statusController.text,
      };

      try {
        if (isEditing) {
          // عملية تعديل
          await provider.updateJob(context, widget.job!.jobId!, jobData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث فرصة العمل بنجاح.')),
          );
        } else {
          // عملية إنشاء
          await provider.createJob(context, jobData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء فرصة العمل بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى شاشة قائمة فرص العمل
        Navigator.pop(context);

      } catch (e) {
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.toString()}';
        if (e is ApiException && e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _qualificationController.dispose();
    _siteController.dispose();
    _dateController.dispose();
    _skillsController.dispose();
    _typeController.dispose();
    _endDateController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminJobProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل فرصة عمل' : 'إضافة فرصة عمل جديدة'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقل User ID (لتعيين الناشر بواسطة الأدمن)
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'معرف الناشر (UserID)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال معرف الناشر';
                  }
                  if (int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح لمعرف الناشر';
                  }
                  // TODO: تحقق من وجود UserID ومدى كونه لمدير شركة/أدمن
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل المسمى الوظيفي
              TextFormField(
                controller: _jobTitleController,
                decoration: const InputDecoration(labelText: 'المسمى الوظيفي'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المسمى الوظيفي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل الوصف
              TextFormField(
                controller: _jobDescriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوصف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل المؤهلات
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: 'المؤهلات'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // حقل المكان
              TextFormField(
                controller: _siteController,
                decoration: const InputDecoration(labelText: 'المكان'),
              ),
              const SizedBox(height: 12),
              // حقل تاريخ النشر
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ النشر',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار تاريخ النشر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل المهارات (كنص)
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(labelText: 'المهارات المطلوبة (كنص)'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // حقل النوع (وظيفة/تدريب) - يمكن استبداله بـ Dropdown
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'النوع (وظيفة / تدريب)'),
                validator: (value) {
                  if (value == null || value.isEmpty || (!['وظيفة', 'تدريب'].contains(value))) {
                    return 'الرجاء إدخال "وظيفة" أو "تدريب"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل تاريخ الانتهاء (مع منتقي تاريخ)
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ الانتهاء',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectEndDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  // يمكن أن يكون تاريخ الانتهاء اختيارياً
                  // إذا تم إدخاله، تحقق من أنه بعد تاريخ النشر
                  if (_selectedDate != null && _selectedEndDate != null && _selectedEndDate!.isBefore(_selectedDate!)) {
                    return 'تاريخ الانتهاء يجب أن يكون بعد تاريخ النشر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل الحالة (مفعل/معلق/محذوف) - يمكن استبداله بـ Dropdown
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'الحالة (مفعل / معلق / محذوف)'),
                validator: (value) {
                  if (value == null || value.isEmpty || (!['مفعل', 'معلق', 'محذوف'].contains(value))) {
                    return 'الرجاء إدخال "مفعل" أو "معلق" أو "محذوف"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: _saveJob,
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء فرصة العمل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}