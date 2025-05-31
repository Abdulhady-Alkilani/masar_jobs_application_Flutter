import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_course_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../models/training_course.dart';
import '../services/api_service.dart'; // تأكد من المسار
// قد تحتاج لاستيراد provider للمستخدمين لاختيار المؤلف إذا لزم الأمر


class CreateEditCourseScreen extends StatefulWidget {
  final TrainingCourse? course; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const CreateEditCourseScreen({Key? key, this.course}) : super(key: key);

  @override
  _CreateEditCourseScreenState createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController(); // لتعيين المؤلف (لـ Admin)
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _trainersNameController = TextEditingController();
  final TextEditingController _courseDescriptionController = TextEditingController();
  final TextEditingController _siteController = TextEditingController(); // أو Dropdown (حضوري/اونلاين)
  final TextEditingController _trainersSiteController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _enrollHyperLinkController = TextEditingController();
  final TextEditingController _stageController = TextEditingController(); // أو Dropdown (مبتدئ/متوسط/متقدم)
  final TextEditingController _certificateController = TextEditingController(); // أو Checkbox/Switch

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;


  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقول بالبيانات الحالية للدورة
    if (isEditing) {
      _userIdController.text = widget.course!.userId?.toString() ?? '';
      _courseNameController.text = widget.course!.courseName ?? '';
      _trainersNameController.text = widget.course!.trainersName ?? '';
      _courseDescriptionController.text = widget.course!.courseDescription ?? '';
      _siteController.text = widget.course!.site ?? '';
      _trainersSiteController.text = widget.course!.trainersSite ?? '';
      _selectedStartDate = widget.course!.startDate;
      _startDateController.text = _selectedStartDate?.toString().split(' ')[0] ?? '';
      _selectedEndDate = widget.course!.endDate;
      _endDateController.text = _selectedEndDate?.toString().split(' ')[0] ?? '';
      _enrollHyperLinkController.text = widget.course!.enrollHyperLink ?? '';
      _stageController.text = widget.course!.stage ?? '';
      _certificateController.text = widget.course!.certificate ?? '';
    } else {
      // يمكن تعيين تاريخ البداية الافتراضي
      // _selectedStartDate = DateTime.now();
      // _startDateController.text = _selectedStartDate?.toString().split(' ')[0] ?? '';
    }

    // TODO: إذا كنت ستستخدم Dropdown لأنواع محددة (مثل Site, Stage, Certificate)، قم بتهيئة الخيارات
    // TODO: إذا كنت ستسمح باختيار المؤلف (UserID) من قائمة، قم بجلب قائمة المستخدمين
  }

  // تابع لاختيار تاريخ البداية
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  // تابع لاختيار تاريخ الانتهاء
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime(2000), // لا يمكن أن يكون قبل تاريخ البداية
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = picked.toString().split(' ')[0];
      });
    }
  }


  // تابع لحفظ (إنشاء أو تعديل) الدورة
  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminCourseProvider>(context, listen: false);

      final courseData = {
        'UserID': int.tryParse(_userIdController.text), // تحويل النص إلى عدد صحيح
        'Course name': _courseNameController.text,
        'Trainers name': _trainersNameController.text,
        'Course Description': _courseDescriptionController.text,
        'Site': _siteController.text,
        'Trainers Site': _trainersSiteController.text,
        'Start Date': _selectedStartDate?.toIso8601String().split('T')[0],
        'End Date': _selectedEndDate?.toIso8601String().split('T')[0],
        'Enroll Hyper Link': _enrollHyperLinkController.text,
        'Stage': _stageController.text,
        'Certificate': _certificateController.text,
      };

      try {
        if (isEditing) {
          // عملية تعديل
          await provider.updateCourse(context, widget.course!.courseId!, courseData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الدورة بنجاح.')),
          );
        } else {
          // عملية إنشاء
          await provider.createCourse(context, courseData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الدورة بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى شاشة قائمة الدورات
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
    _courseNameController.dispose();
    _trainersNameController.dispose();
    _courseDescriptionController.dispose();
    _siteController.dispose();
    _trainersSiteController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _enrollHyperLinkController.dispose();
    _stageController.dispose();
    _certificateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminCourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل دورة' : 'إضافة دورة جديدة'),
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
              // حقل User ID (لتعيين المؤلف بواسطة الأدمن)
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
                  // TODO: تحقق من وجود UserID
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل اسم الدورة
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(labelText: 'اسم الدورة'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الدورة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل اسم المدرب
              TextFormField(
                controller: _trainersNameController,
                decoration: const InputDecoration(labelText: 'اسم المدرب'),
              ),
              const SizedBox(height: 12),
              // حقل وصف الدورة
              TextFormField(
                controller: _courseDescriptionController,
                decoration: const InputDecoration(labelText: 'وصف الدورة'),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              // حقل مكان الدورة (حضوري/اونلاين) - يمكن استبداله بـ Dropdown
              TextFormField(
                controller: _siteController,
                decoration: const InputDecoration(labelText: 'المكان (حضوري / اونلاين)'),
              ),
              const SizedBox(height: 12),
              // حقل جهة التدريب
              TextFormField(
                controller: _trainersSiteController,
                decoration: const InputDecoration(labelText: 'جهة التدريب'),
              ),
              const SizedBox(height: 12),
              // حقل تاريخ البدء (مع منتقي تاريخ)
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ البدء',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectStartDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار تاريخ البدء';
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
                  // يمكن أن يكون تاريخ الانتهاء اختيارياً أو مطلوباً إذا كان تاريخ البدء موجوداً
                  // التحقق من أن تاريخ الانتهاء بعد تاريخ البدء إذا كلاهما موجودين
                  if (_selectedStartDate != null && _selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
                    return 'تاريخ الانتهاء يجب أن يكون بعد تاريخ البدء';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل رابط التسجيل
              TextFormField(
                controller: _enrollHyperLinkController,
                decoration: const InputDecoration(labelText: 'رابط التسجيل'),
                keyboardType: TextInputType.url,
                // validator: (value) { ... }, // التحقق من أنه URL صحيح
              ),
              const SizedBox(height: 12),
              // حقل المستوى (مبتدئ/متوسط/متقدم) - يمكن استبداله بـ Dropdown
              TextFormField(
                controller: _stageController,
                decoration: const InputDecoration(labelText: 'المستوى'),
                // validator: (value) { ... }, // التحقق من أنه قيمة مسموحة
              ),
              const SizedBox(height: 12),
              // حقل الشهادة (يوجد/لا يوجد) - يمكن استبداله بـ Checkbox/Switch
              TextFormField(
                controller: _certificateController,
                decoration: const InputDecoration(labelText: 'شهادة (يوجد / لا يوجد)'),
                // validator: (value) { ... }, // التحقق من أنه قيمة مسموحة
              ),
              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: _saveCourse,
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء الدورة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO: يمكنك إنشاء شاشات CreateEdit لنماذج أخرى بنفس النمط (Company, Job, Skill, Group)