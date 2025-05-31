import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_job_provider.dart'; // للأدمن
import '../providers/managed_job_opportunity_provider.dart'; // للمدير
import '../providers/auth_provider.dart'; // لمعرفة نوع المستخدم
import '../models/job_opportunity.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
import '../models/user.dart'; // لاستخدام موديل المستخدم
// import '../models/api_exception.dart'; // <--- تأكد من استيراد ApiException بشكل صحيح

class EditJobScreen extends StatefulWidget {
  final JobOpportunity? job; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const EditJobScreen({Key? key, this.job}) : super(key: key);

  @override
  _EditJobScreenState createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  final TextEditingController _userIdController = TextEditingController(); // للأدمن فقط: لتعيين الناشر
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // تاريخ النشر
  final TextEditingController _skillsController = TextEditingController(); // كنص أو JSON
  // حقول Dropdown
  String? _selectedType; // (وظيفة/تدريب)
  String? _selectedStatus; // (مفعل/معلق/محذوف)

  DateTime? _selectedDate; // لتخزين التاريخ المختار لمنتقي التاريخ
  DateTime? _selectedEndDate;


  bool get isEditing => widget.job != null; // للتحقق بسهولة إذا كانت شاشة تعديل

  @override
  void initState() {
    super.initState();
    // تعبئة الحقول بالبيانات الحالية للوظيفة إذا كانت شاشة تعديل
    if (isEditing) {
      _userIdController.text = widget.job!.userId?.toString() ?? '';
      _jobTitleController.text = widget.job!.jobTitle ?? '';
      _jobDescriptionController.text = widget.job!.jobDescription ?? '';
      _qualificationController.text = widget.job!.qualification ?? '';
      _siteController.text = widget.job!.site ?? '';
      _selectedDate = widget.job!.date;
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
      _skillsController.text = widget.job!.skills ?? '';
      _selectedType = widget.job!.type; // تعيين القيمة الافتراضية لـ Dropdown
      _selectedEndDate = widget.job!.endDate;
      // _endDateController.text = _selectedEndDate?.toString().split(' ')[0] ?? '';
      _selectedStatus = widget.job!.status; // تعيين القيمة الافتراضية لـ Dropdown
    } else {
      // في حالة الإضافة، تعيين قيم افتراضية إذا لزم الأمر
      _selectedDate = DateTime.now();
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
      _selectedType = 'وظيفة'; // قيمة افتراضية للنوع
      _selectedStatus = 'مفعل'; // قيمة افتراضية للحالة
    }
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
    // Initial date should be today or selected start date if available
    final DateTime initialDate = _selectedEndDate ?? _selectedDate ?? DateTime.now();
    // First selectable date should be the selected start date or the earliest possible date
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
        // _endDateController.text = picked.toString().split(' ')[0];
      });
    }
  }


  // تابع لحفظ (إنشاء أو تعديل) فرصة العمل
  Future<void> _saveJob() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // تحديد provider المناسب بناءً على نوع المستخدم الحالي
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final User? currentUser = authProvider.user;

      if (currentUser == null) {
        // هذا لا ينبغي أن يحدث إذا كانت الشاشة محمية بشكل صحيح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: بيانات المستخدم غير متوفرة.')),
        );
        return;
      }

      // بيانات الوظيفة المراد إرسالها
      final jobData = {
        // UserID فقط للأدمن في حالة الإنشاء أو التعديل، وإلا سيتم تعيينه في backend
        if (currentUser.type == 'Admin' && _userIdController.text.isNotEmpty)
          'UserID': int.tryParse(_userIdController.text), // يجب أن يكون عدد صحيح
        'Job Title': _jobTitleController.text,
        'Job Description': _jobDescriptionController.text,
        'Qualification': _qualificationController.text.isEmpty ? null : _qualificationController.text,
        'Site': _siteController.text.isEmpty ? null : _siteController.text,
        'Date': _selectedDate?.toIso8601String().split('T')[0], // إرسال التاريخ بصيغة YYYY-MM-DD
        'Skills': _skillsController.text.isEmpty ? null : _skillsController.text,
        'Type': _selectedType, // القيمة المختارة من Dropdown
        'End Date': _selectedEndDate?.toIso8601String().split('T')[0], // إرسال التاريخ بصيغة YYYY-MM-DD أو null
        'Status': _selectedStatus, // القيمة المختارة من Dropdown
      };

      try {
        if (isEditing) {
          // عملية تعديل
          // استخدام provider المناسب based on user type
          if (currentUser.type == 'Admin') {
            final adminProvider = Provider.of<AdminJobProvider>(context, listen: false);
            // تأكد من أن API يقبل UserID في PUT
            await adminProvider.updateJob(context, widget.job!.jobId!, jobData);
          } else if (currentUser.type == 'مدير شركة') {
            final managedProvider = Provider.of<ManagedJobOpportunityProvider>(context, listen: false);
            // المدير لا يرسل UserID، backend يضعه تلقائياً
            jobData.remove('UserID');
            await managedProvider.updateJob(context, widget.job!.jobId!, jobData);
          } else {
            // نوع مستخدم غير مصرح له بالتعديل (لا ينبغي الوصول هنا)
            throw ApiException(403, 'You are not authorized to update jobs.');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث فرصة العمل بنجاح.')),
          );

        } else {
          // عملية إنشاء
          if (currentUser.type == 'Admin') {
            final adminProvider = Provider.of<AdminJobProvider>(context, listen: false);
            // في حالة إنشاء الأدمن، يتم تضمين UserID المؤلف في jobData
            await adminProvider.createJob(context, jobData);

          } else if (currentUser.type == 'مدير شركة') {
            final managedProvider = Provider.of<ManagedJobOpportunityProvider>(context, listen: false);
            // عند إنشاء المدير، لا يرسل UserID، backend يضعه تلقائياً
            jobData.remove('UserID'); // إزالة UserID إذا أرسله الفورم
            await managedProvider.createJob(context, jobData);

          } else {
            // نوع مستخدم غير مصرح له بالإنشاء
            throw ApiException(403, 'You are not authorized to create jobs.');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء فرصة العمل بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى الشاشة السابقة
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية في الفورم (باستخدام مفتاح الفورم وتحكمات حقول النصوص)
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.toString()}')),
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
    // _typeController.dispose(); // Dropdown controllers might not need dispose like text controllers if their state is managed by the form/widget lifecycle
    // _endDateController.dispose();
    // _statusController.dispose(); // Dropdown controllers
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // نحتاج لمعرفة نوع المستخدم لعرض/إخفاء حقول معينة وتحديد Provider الصحيح
    final currentUser = Provider.of<AuthProvider>(context).user;

    // نستخدم Provider المناسب للاستماع لحالة التحميل عند الحفظ
    // هنا نستخدم Selector أو Consumer لتجنب إعادة بناء الواجهة بالكامل إلا عند تغير isLoading
    final bool isLoading = currentUser?.type == 'Admin'
        ? context.select((AdminJobProvider p) => p.isLoading)
        : context.select((ManagedJobOpportunityProvider p) => p.isLoading);


    // إذا لم يتم تحميل المستخدم الحالي بعد أو حدث خطأ
    if (currentUser == null) {
      return Scaffold(appBar: AppBar(title: const Text('خطأ')), body: const Center(child: Text('بيانات المستخدم غير متوفرة.')));
    }

    // تحديد ما إذا كان المستخدم الحالي هو الأدمن
    bool isAdmin = currentUser.type == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل فرصة عمل' : 'إضافة فرصة عمل جديدة'),
      ),
      body: isLoading // استخدام حالة التحميل الإجمالية هنا
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقل User ID (خاص بالأدمن فقط)
              if (isAdmin) // عرض الحقل فقط إذا كان المستخدم أدمن
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
                    // TODO: يمكنك إضافة تحقق هنا للتأكد من وجود UserID ومدى كونه لمدير شركة/أدمن (اختياري في الواجهة، يتم التحقق في Backend)
                    return null;
                  },
                ),
              if (isAdmin) const SizedBox(height: 12), // مسافة إذا تم عرض حقل UserID

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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'النوع'),
                value: _selectedType, // استخدام _selectedType مباشرة
                items: const [
                  DropdownMenuItem<String>(value: 'وظيفة', child: Text('وظيفة')),
                  DropdownMenuItem<String>(value: 'تدريب', child: Text('تدريب')),
                ],
                onChanged: (newValue) {
                  _selectedType = newValue; // تحديث _selectedType
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
                // controller: _endDateController,
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'الحالة'),
                value: _selectedStatus, // استخدام _selectedStatus مباشرة
                items: const [
                  DropdownMenuItem<String>(value: 'مفعل', child: Text('مفعل')),
                  DropdownMenuItem<String>(value: 'معلق', child: Text('معلق')),
                  DropdownMenuItem<String>(value: 'محذوف', child: Text('محذوف')),
                ],
                onChanged: (newValue) {
                  _selectedStatus = newValue; // تحديث _selectedStatus
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الحالة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: isLoading ? null : _saveJob, // استخدام حالة التحميل الإجمالية هنا
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء فرصة العمل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}