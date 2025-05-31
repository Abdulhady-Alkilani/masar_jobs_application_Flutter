import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_training_course_provider.dart'; // نستخدم Provider العام لجلب التفاصيل
import '../models/training_course.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
import '../providers/auth_provider.dart'; // لمعرفة حالة المصادقة لعرض زر التسجيل
import '../providers/my_enrollments_provider.dart'; // للتسجيل في الدورة
// قد تحتاج لاستيراد شاشة تسجيل الدخول إذا كان المستخدم غير مسجل


class TrainingCourseDetailScreen extends StatefulWidget {
  final int courseId; // معرف الدورة

  const TrainingCourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _TrainingCourseDetailScreenState createState() => _TrainingCourseDetailScreenState();
}

class _TrainingCourseDetailScreenState extends State<TrainingCourseDetailScreen> {
  TrainingCourse? _course;
  String? _courseError;
  bool _isLoading = false; // حالة تحميل خاصة بهذه الشاشة لجلب التفاصيل

  @override
  void initState() {
    super.initState();
    _fetchCourse(); // جلب تفاصيل الدورة عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل الدورة المحدد
  Future<void> _fetchCourse() async {
    setState(() { _isLoading = true; _courseError = null; });
    final courseProvider = Provider.of<PublicTrainingCourseProvider>(context, listen: false);

    try {
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

  // تابع للتسجيل في الدورة
  Future<void> _enrollInCourse(BuildContext context) async {
    // الحصول على provider التسجيل والتحقق من المصادقة
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context, listen: false);

    // تحقق مما إذا كان المستخدم مسجل دخول
    if (!authProvider.isAuthenticated) {
      // TODO: عرض رسالة للمستخدم أو الانتقال لشاشة تسجيل الدخول
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول للتسجيل في الدورة.')),
      );
      // Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      return;
    }

    // تحقق مما إذا كان المستخدم خريجاً (إذا كان التسجيل متاحاً للخريجين فقط)
    // if (authProvider.user?.type != 'خريج') {
    //    ScaffoldMessenger.of(context).showSnackBar(
    //      const SnackBar(content: Text('التسجيل في الدورات متاح للخريجين فقط.')),
    //   );
    //   return;
    // }


    // TODO: يمكن إضافة AlertDialog للتأكيد قبل التسجيل

    // استدعاء تابع التسجيل في Provider
    try {
      await enrollmentsProvider.enrollInCourse(context, widget.courseId);

      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التسجيل في الدورة بنجاح!')),
      );
      // TODO: تحديث حالة زر التسجيل (مثلاً إخفاؤه أو تغييره إلى "مسجل بالفعل")
      // هذا يتطلب إعادة بناء الشاشة أو جزء منها بناءً على حالة Provider التسجيل.
      // يمكنك استخدام Consumer أو الاستماع لـ MyEnrollmentsProvider هنا.

    } on ApiException catch (e) {
      String errorMessage = 'فشل التسجيل: ${e.message}';
      if (e.statusCode == 409) { // Conflict - Already enrolled
        errorMessage = 'أنت مسجل بالفعل في هذه الدورة.';
      }
      if (e.errors != null) {
        e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التسجيل في الدورة: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // هنا نستمع لـ MyEnrollmentsProvider لمعرفة ما إذا كان المستخدم مسجل بالفعل (اختياري)
    final enrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context);
    // حالة التحميل للتسجيل نفسه
    final bool isEnrolling = enrollmentsProvider.isLoading;
    // التحقق مما إذا كان المستخدم مسجل بالفعل (تحتاج إلى جلب قائمة التسجيلات أولاً)
    // يمكنك جلب قائمة التسجيلات في initState أو استخدام Consumer here.
    // For simplicity here, we assume enrollmentsProvider.enrollments is loaded.
    final bool isAlreadyEnrolled = enrollmentsProvider.enrollments.any((enrollment) => enrollment.courseId == widget.courseId);


    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.courseName ?? 'تفاصيل الدورة'),
      ),
      body: _isLoading // حالة التحميل الخاصة بالشاشة (جلب التفاصيل)
          ? const Center(child: CircularProgressIndicator())
          : _courseError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: ${_courseError!}'))
          : _course == null // بيانات غير موجودة بعد التحميل
          ? const Center(child: Text('الدورة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الدورة
            Text(
              _course!.courseName ?? 'بدون عنوان',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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

            const SizedBox(height: 24),

            // TODO: زر التسجيل في الدورة
            // بناءً على حالة المستخدم (مصادق عليه وخريج) وحالة الدورة (متاحة للتسجيل) وحالة التسجيل الحالية للمستخدم
            if (isAlreadyEnrolled) // إذا كان مسجل بالفعل
              const Center(
                child: Text('أنت مسجل بالفعل في هذه الدورة.', style: TextStyle(fontSize: 16, color: Colors.green)),
              )
            else if (isEnrolling) // إذا كان يتم عملية التسجيل حالياً
              const Center(child: CircularProgressIndicator())
            else // إذا لم يكن مسجل بالفعل وليس في عملية تسجيل
              Center(
                child: ElevatedButton(
                  onPressed: () => _enrollInCourse(context), // استدعاء تابع التسجيل
                  child: const Text('التسجيل في الدورة'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}