import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_job_opportunity_provider.dart'; // لتنفيذ عملية الإنشاء
import '../services/api_service.dart'; // لاستخدام ApiException


class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  _CreateJobScreenState createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // تاريخ النشر
  final TextEditingController _skillsController = TextEditingController(); // كنص أو JSON
  final TextEditingController _enrollHyperLinkController = TextEditingController(); // رابط التسجيل (أضفته لأن API model يحتوي عليه)
  final TextEditingController _stageController = TextEditingController(); // أو Dropdown (مبتدئ/متوسط/متقدم)
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  // حقول Dropdown
  String? _selectedType; // (وظيفة/تدريب)
  String? _selectedStatus; // (مفعل/معلق/محذوف)
  String? _selectedCertificate; // (يوجد/لا يوجد) - أضفته لأن API model يحتوي عليه


  DateTime? _selectedDate; // لتخزين التاريخ المختار لمنتقي التاريخ
  DateTime? _selectedEndDate;


  // TODO: قائمة أنواع الوظائف (وظيفة/تدريب)
  final List<String> _jobTypes = ['وظيفة', 'تدريب'];
  // TODO: قائمة حالات الوظائف (مفعل/معلق/محذوف)
  final List<String> _jobStatuses = ['مفعل', 'معلق', 'محذوف'];
  // TODO: قائمة حالات الشهادة (يوجد/لا يوجد)
  final List<String> _certificateStatuses = ['يوجد', 'لا يوجد'];
  // TODO: قائمة مستويات الدورة (مبتدئ/متوسط/متقدم)
  final List<String> _stageLevels = ['مبتدئ', 'متوسط', 'متقدم'];


  @override
  void initState() {
    super.initState();
    // تعيين قيم افتراضية للحقول الجديدة
    _selectedDate = DateTime.now();
    _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
    _selectedType = _jobTypes.isNotEmpty ? _jobTypes.first : null; // تعيين أول نوع كافتراضي
    _selectedStatus = _jobStatuses.isNotEmpty ? _jobStatuses.first : null; // تعيين أول حالة كافتراضي
    _selectedCertificate = _certificateStatuses.isNotEmpty ? _certificateStatuses.first : null; // تعيين أول حالة شهادة كافتراضي
    _stageController.text = _stageLevels.isNotEmpty ? _stageLevels.first : ''; // تعيين أول مستوى كافتراضي كنص


    // إذا كنت تستخدم هذه الشاشة لتعديل دورة (CreateEditCourseScreen)
    // قم بتعبئة الحقول من كائن الدورة الممرر في حالة التعديل
    // هذا الكود هنا مخصص لـ CreateJobScreen فقط
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
    final DateTime initialDate = _selectedEndDate ?? _selectedDate ?? DateTime.now();
    final DateTime firstDate = _selectedDate ?? DateTime(2000);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = picked.toString().split(' ')[0];
      });
    }
  }


  // تابع لإنشاء فرصة العمل
  Future<void> _createJob() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<ManagedJobOpportunityProvider>(context, listen: false);

      // بيانات الوظيفة المراد إرسالها
      final jobData = {
        // لا يتم إرسال UserID هنا، Backend يعرف المؤلف من التوكن (مدير الشركة)
        'Job Title': _jobTitleController.text,
        'Job Description': _jobDescriptionController.text,
        'Qualification': _qualificationController.text.isEmpty ? null : _qualificationController.text,
        'Site': _siteController.text.isEmpty ? null : _siteController.text,
        'Date': _selectedDate?.toIso8601String().split('T')[0], // YYYY-MM-DD
        'Skills': _skillsController.text.isEmpty ? null : _skillsController.text,
        'Type': _selectedType, // القيمة المختارة من Dropdown
        'End Date': _selectedEndDate?.toIso8601String().split('T')[0], // YYYY-MM-DD أو null
        'Status': _selectedStatus, // القيمة المختارة من Dropdown
        /* كانو الثلاثة التاليات معلقات*/
         'Enroll Hyper Link': _enrollHyperLinkController.text.isEmpty ? null : _enrollHyperLinkController.text, // هذا حقل للدورة التدريبية!
         'Stage': _stageController.text.isEmpty ? null : _stageController.text, // هذا حقل للدورة التدريبية!
         'Certificate': _selectedCertificate, // هذا حقل للدورة التدريبية!
      };

      try {
        // عملية إنشاء
        await provider.createJob(context, jobData); // استدعاء تابع الإنشاء

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء فرصة العمل بنجاح.')),
        );
        // بعد النجاح، العودة إلى الشاشة السابقة (قائمة الوظائف المنشورة)
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل الإنشاء: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية في الفورم
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإنشاء: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    // لا تنسى dispose لجميع حقول التحكم بالنصوص
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _qualificationController.dispose();
    _siteController.dispose();
    _dateController.dispose();
    _skillsController.dispose();
    _typeController.dispose(); // Dropdown controllers might not need dispose
    _endDateController.dispose();
    _statusController.dispose(); // Dropdown controllers
    _enrollHyperLinkController.dispose(); // أضفتها
    _stageController.dispose(); // أضفتها
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من ManagedJobOpportunityProvider عند الحفظ
    final provider = Provider.of<ManagedJobOpportunityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة فرصة عمل جديدة'), // دائماً شاشة إضافة
      ),
      body: provider.isLoading // إذا كان Provider يحمل بيانات (عند الحفظ)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقول بيانات الوظيفة
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
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: 'المؤهلات'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _siteController,
                decoration: const InputDecoration(labelText: 'المكان'),
              ),
              const SizedBox(height: 12),
              // حقل تاريخ النشر (مع منتقي تاريخ) - سيكون مقروء فقط ويأخذ القيمة الافتراضية الحالية
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ النشر',
                  // لا يوجد زر اختيار تاريخ هنا، يأخذ التاريخ الحالي افتراضاً عند الإنشاء
                  // suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context)),
                ),
                readOnly: true, // للقراءة فقط
                // validator لا حاجة له إذا كان يأخذ الافتراضي دائماً
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
              // حقل النوع (وظيفة/تدريب) - Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'النوع'),
                value: _selectedType,
                items: _jobTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _selectedType = newValue;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار النوع';
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
              // حقل الحالة (مفعل/معلق/محذوف) - Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'الحالة'),
                value: _selectedStatus,
                items: _jobStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _selectedStatus = newValue;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الحالة';
                  }
                  return null;
                },
              ),
              // TODO: إضافة حقل رابط التسجيل (للدورات) - هذا ليس لوظيفة
              // TODO: إضافة حقل المستوى (للدورات) - هذا ليس لوظيفة
              // TODO: إضافة حقل الشهادة (للدورات) - هذا ليس لوظيفة


              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _createJob, // تعطيل الزر أثناء التحميل
                child: const Text('إنشاء فرصة العمل'), // دائماً نص إنشاء
              ),
            ],
          ),
        ),
      ),
    );
  }
}