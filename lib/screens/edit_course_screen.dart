import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_training_course_provider.dart'; // لتنفيذ عملية التحديث وجلب التفاصيل
import '../models/training_course.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// لا تحتاج AuthProvider هنا بشكل مباشر إلا إذا أردت التحقق من الصلاحيات في الواجهة


class EditCourseScreen extends StatefulWidget {
  final int courseId; // معرف الدورة التي سيتم تعديلها

  const EditCourseScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _EditCourseScreenState createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  // لا نحتاج حقل userId هنا، لأن المدير/الاستشاري يعدل دوره الخاص والـ Backend يعرف المؤلف من التوكن
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _trainersNameController = TextEditingController();
  final TextEditingController _courseDescriptionController = TextEditingController();
  // حقول Dropdown أو TextFields لقيم محددة
  final TextEditingController _siteController = TextEditingController(); // أو Dropdown (حضوري/اونلاين)
  final TextEditingController _trainersSiteController = TextEditingController();
  final TextEditingController _enrollHyperLinkController = TextEditingController();
  final TextEditingController _stageController = TextEditingController(); // أو Dropdown (مبتدئ/متوسط/متقدم)
  final TextEditingController _certificateController = TextEditingController(); // أو Checkbox/Switch

  // حقول التاريخ
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // حالة تحميل خاصة بالشاشة لجلب البيانات الأولية
  bool _isFetchingInitialData = true;
  String? _initialDataError;


  @override
  void initState() {
    super.initState();
    _fetchCourseDetails(); // جلب تفاصيل الدورة عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل الدورة لتعبئة النموذج
  Future<void> _fetchCourseDetails() async {
    setState(() { _isFetchingInitialData = true; _initialDataError = null; });
    final courseProvider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);

    try {
      // استخدام تابع جلب دورة واحدة من Provider (يفترض وجوده أو استخدامه من القائمة المحملة)
      // ManagedTrainingCourseProvider لديه تابع fetchCourseOpportunity الذي يجلب من القائمة المحلية
      final course = await courseProvider.fetchCourseOpportunity(widget.courseId); // جلب من القائمة المحملة

      if (course != null) {
        // تعبئة الحقول بالبيانات
        _courseNameController.text = course.courseName ?? '';
        _trainersNameController.text = course.trainersName ?? '';
        _courseDescriptionController.text = course.courseDescription ?? '';
        _siteController.text = course.site ?? '';
        _trainersSiteController.text = course.trainersSite ?? '';
        _selectedStartDate = course.startDate;
        _startDateController.text = _selectedStartDate?.toString().split(' ')[0] ?? '';
        _selectedEndDate = course.endDate;
        _endDateController.text = _selectedEndDate?.toString().split(' ')[0] ?? '';
        _enrollHyperLinkController.text = course.enrollHyperLink ?? '';
        _stageController.text = course.stage ?? '';
        _certificateController.text = course.certificate ?? '';
      } else {
        // إذا لم تُعثر على الدورة في القائمة المحلية (ربما تحتاج لجلبها من API مباشرة هنا)
        // TODO: إذا لم تكن الدورة موجودة في القائمة، أضف تابع fetchSingleManagedCourse(BuildContext context, int courseId) في Provider و ApiService واجلبه هنا
        setState(() { _initialDataError = 'الدورة بمعرف ${widget.courseId} غير موجودة في القائمة المحملة.'; });
      }

    } catch (e) {
      setState(() { _initialDataError = 'فشل جلب تفاصيل الدورة الأولية: ${e.toString()}'; });
    } finally {
      setState(() { _isFetchingInitialData = false; });
    }
  }


  // تابع لاختيار تاريخ البدء
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
    final DateTime initialDate = _selectedEndDate ?? _selectedStartDate ?? DateTime.now();
    final DateTime firstDate = _selectedStartDate ?? DateTime(2000);

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


  // تابع لحفظ التعديلات
  Future<void> _saveCourse() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);

      final courseData = {
        // لا يتم إرسال UserID هنا، Backend يعرف المؤلف من التوكن
        'Course name': _courseNameController.text,
        'Trainers name': _trainersNameController.text,
        'Course Description': _courseDescriptionController.text,
        'Site': _siteController.text.isEmpty ? null : _siteController.text,
        'Trainers Site': _trainersSiteController.text.isEmpty ? null : _trainersSiteController.text,
        'Start Date': _selectedStartDate?.toIso8601String().split('T')[0], // YYYY-MM-DD أو null
        'End Date': _selectedEndDate?.toIso8601String().split('T')[0], // YYYY-MM-DD أو null
        'Enroll Hyper Link': _enrollHyperLinkController.text.isEmpty ? null : _enrollHyperLinkController.text, // أو Null إذا فارغ
        'Stage': _stageController.text.isEmpty ? null : _stageController.text, // أو Null إذا فارغ
        'Certificate': _certificateController.text.isEmpty ? null : _certificateController.text, // أو Null إذا فارغ
      };

      try {
        // عملية تعديل (دائماً في هذه الشاشة)
        await provider.updateCourse(context, widget.courseId, courseData); // استدعاء تابع التحديث

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الدورة بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة تفاصيل الدورة أو قائمة الدورات
        // الأفضل العودة لشاشة التفاصيل، ويفضل أن تقوم شاشة التفاصيل بإعادة جلب البيانات بعد العودة
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل التحديث: ${e.message}';
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
          SnackBar(content: Text('فشل التحديث: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    // لا تنسى dispose لجميع حقول التحكم بالنصوص
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
    // الاستماع لحالة التحميل من ManagedTrainingCourseProvider عند الحفظ
    final provider = Provider.of<ManagedTrainingCourseProvider>(context);


    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل دورة تدريبية'), // دائماً شاشة تعديل
      ),
      body: _isFetchingInitialData // حالة تحميل البيانات الأولية للشاشة
          ? const Center(child: CircularProgressIndicator())
          : _initialDataError != null // خطأ في جلب البيانات الأولية
          ? Center(child: Text('Error loading initial data: ${_initialDataError!}'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                // validator: (value) { ... }, // التحقق من القيم المسموحة
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
                  // يمكن أن يكون تاريخ الانتهاء اختيارياً
                  // إذا تم إدخاله، تحقق من أنه بعد تاريخ البدء
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
                onPressed: provider.isLoading ? null : _saveCourse, // تعطيل الزر أثناء التحميل
                child: const Text('حفظ التعديلات'), // دائماً نص حفظ التعديلات
              ),
            ],
          ),
        ),
      ),
    );
  }
}