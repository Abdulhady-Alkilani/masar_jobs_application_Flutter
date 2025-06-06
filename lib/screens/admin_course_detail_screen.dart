import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_course_provider.dart'; // نحتاجها لتنفيذ التعديل/الحذف وربما جلب التفاصيل
import '../providers/public_training_course_provider.dart'; // قد نستخدمه لجلب التفاصيل إذا لم يكن لدينا تابع في AdminProvider
import '../models/training_course.dart';
import '../services/api_service.dart';
import 'create_edit_course_screen.dart'; // تأكد من المسار
// استيراد شاشة التعديل

class AdminCourseDetailScreen extends StatefulWidget {
  final int courseId; // معرف الدورة

  const AdminCourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _AdminCourseDetailScreenState createState() => _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState extends State<AdminCourseDetailScreen> {
  TrainingCourse? _course;
  String? _courseError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCourse(); // جلب تفاصيل الدورة عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل الدورة المحدد
  Future<void> _fetchCourse() async {
    setState(() { _isLoading = true; _courseError = null; });

    // هنا يمكن أن نستخدم تابع جلب تفاصيل الدورة من PublicProvider
    // أو إذا أضفنا تابعاً خاصاً بالأدمن في AdminCourseProvider يجلبه بتفاصيل إضافية
    final courseProvider = Provider.of<PublicTrainingCourseProvider>(context, listen: false); // استخدام الـ Public Provider لسهولة الجلب الفردي
    // OR: final adminProvider = Provider.of<AdminCourseProvider>(context, listen: false);

    try {
      // إذا كان هناك تابع fetchSingleCourse في AdminCourseProvider، استخدمه
      // final fetchedCourse = await adminProvider.fetchSingleCourse(widget.courseId);
      // وإلا، استخدم التابع من Public Provider
      final fetchedCourse = await courseProvider.fetchTrainingCourse(widget.courseId);


      setState(() {
        _course = fetchedCourse;
        _courseError = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _course = null;
        _courseError = e.message;
      });
    } catch (e) {
      setState(() {
        _course = null;
        _courseError = 'فشل جلب تفاصيل الدورة: ${e.toString()}';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // تابع لحذف الدورة
  Future<void> _deleteCourse(BuildContext context) async {
    final provider = Provider.of<AdminCourseProvider>(context, listen: false);
    if (_course?.courseId == null) return; // تأكد من وجود المعرف

    try {
      // TODO: إضافة AlertDialog للتأكيد قبل الحذف
      await provider.deleteCourse(context, _course!.courseId!);
      // بعد الحذف، العودة إلى شاشة قائمة الدورات
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الدورة بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف الدورة: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إلا إذا كان له حالة تحميل خاصة بعمليات التعديل/الحذف
    // final adminProvider = Provider.of<AdminCourseProvider>(context);


    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.courseName ?? 'تفاصيل الدورة'),
        actions: [
          if (_course != null) ...[ // عرض الأزرار فقط إذا تم جلب الدورة بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: الانتقال إلى شاشة تعديل الدورة (CreateEditCourseScreen)
                print('Edit Course Tapped for ID ${widget.courseId}');
                 Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditCourseScreen(course: _course))); // مرر كائن الدورة
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('وظيفة تعديل الدورة لم تنفذ.')),
                // );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : () => _deleteCourse(context), // تعطيل الزر أثناء التحميل
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courseError != null
          ? Center(child: Text('Error: $_courseError'))
          : _course == null
          ? const Center(child: Text('الدورة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الدورة (مشابه لشاشة التفاصيل العامة، مع تفاصيل إضافية للأدمن)
            Text(
              _course!.courseName ?? 'بدون عنوان',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('الناشر UserID: ${_course!.userId ?? 'غير محدد'}', style: const TextStyle(fontSize: 16)), // عرض UserID الناشر (خاص بالأدمن)
            Text(
              'المدرب: ${_course!.trainersName ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'المكان: ${_course!.site ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'جهة التدريب: ${_course!.trainersSite ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'المستوى: ${_course!.stage ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'الشهادة: ${_course!.certificate ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'تاريخ البدء: ${_course!.startDate?.toString().split(' ')[0] ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 14),
            ),
            if (_course!.endDate != null)
              Text(
                'تاريخ الانتهاء: ${_course!.endDate!.toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 14),
              ),
            if (_course!.enrollHyperLink != null)
              Text(
                'رابط التسجيل: ${_course!.enrollHyperLink!}',
                style: const TextStyle(fontSize: 14, color: Colors.blue), // يمكن جعله clickable
              ),
            const SizedBox(height: 16),
            const Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _course!.courseDescription ?? 'لا يوجد وصف متاح.',
              style: const TextStyle(fontSize: 16),
            ),
            // يمكن إضافة المزيد من التفاصيل
          ],
        ),
      ),
    );
  }
}