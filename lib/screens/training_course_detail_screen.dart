import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_training_course_provider.dart'; // نستخدم Provider العام لجلب التفاصيل
import '../models/training_course.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
import '../providers/auth_provider.dart'; // لمعرفة حالة المصادقة لعرض زر التسجيل
import '../providers/my_enrollments_provider.dart'; // للتسجيل في الدورة
import 'login_screen.dart'; // للانتقال لشاشة تسجيل الدخول

// قد تحتاج لاستيراد حزمة لفتح الروابط (url_launcher)
// import 'package:url_launcher/url_launcher.dart';


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
    // TODO: جلب قائمة تسجيلات المستخدم هنا أو في MyEnrollmentsProvider لتمكين التحقق من isAlreadyEnrolled في build
    // Provider.of<MyEnrollmentsProvider>(context, listen: false).fetchMyEnrollments(context);
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
    // الحصول على providers اللازمة
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context, listen: false);

    // تحقق مما إذا كان المستخدم مسجل دخول
    if (!authProvider.isAuthenticated) {
      // TODO: عرض رسالة للمستخدم أو الانتقال لشاشة تسجيل الدخول (تم التنفيذ الآن)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول للتسجيل في الدورة.')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      return;
    }

    // تحقق مما إذا كان المستخدم خريجاً (إذا كان التسجيل متاحاً للخريجين فقط)
    // final user = authProvider.user;
    // if (user?.type != 'خريج') {
    //    ScaffoldMessenger.of(context).showSnackBar(
    //      const SnackBar(content: Text('التسجيل في الدورات متاح للخريجين فقط.')),
    //   );
    //   return;
    // }


    // TODO: يمكن إضافة AlertDialog للتأكيد قبل التسجيل (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد التسجيل'),
          content: Text('هل أنت متأكد أنك تريد التسجيل في دورة "${_course?.courseName ?? 'بدون عنوان'}"؟'),
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('التسجيل'), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم التسجيل
      // استدعاء تابع التسجيل في Provider
      try {
        await enrollmentsProvider.enrollInCourse(context, widget.courseId);

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التسجيل في الدورة بنجاح!')),
        );
        // TODO: تحديث حالة زر التسجيل (سيتم تلقائياً عند إعادة بناء الـ Widget إذا تم تحديث حالة isAlreadyEnrolled)

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
      } finally {
        // لا حاجة لتحديث حالة التحميل هنا، Provider سيتكفل بذلك
      }
    }
  }

  // TODO: تابع لفتح رابط التسجيل إذا كان موجوداً (يتطلب url_launcher)
  /*
  Future<void> _launchUrl(String urlString) async {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
   }
   */


  @override
  Widget build(BuildContext context) {
    // هنا نستمع لـ MyEnrollmentsProvider لمعرفة ما إذا كان المستخدم مسجل بالفعل
    final enrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context);
    // حالة التحميل للتسجيل نفسه (خاصة بـ MyEnrollmentsProvider)
    final bool isEnrolling = enrollmentsProvider.isLoading;
    // التحقق مما إذا كان المستخدم مسجل بالفعل (يعتمد على أن قائمة التسجيلات محملة)
    final bool isAlreadyEnrolled = enrollmentsProvider.enrollments.any((enrollment) => enrollment.courseId == widget.courseId);

    // نحتاج أيضاً حالة مصادقة المستخدم من AuthProvider لتحديد ما إذا كان زر التسجيل سيعرض
    final authProvider = Provider.of<AuthProvider>(context);


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
                style: const TextStyle(fontSize: 14, color: Colors.blue), // TODO: جعله clickable
                // يمكن إضافة onTap لاستدعاء _launchUrl
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
            if (!authProvider.isAuthenticated) // إذا لم يكن المستخدم مسجل دخول
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // الانتقال لشاشة تسجيل الدخول
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  },
                  child: const Text('سجل دخول للتسجيل'),
                ),
              )
            // تحقق مما إذا كان المستخدم خريجاً إذا كان ذلك شرطاً للتسجيل
            // else if (authProvider.user?.type != 'خريج')
            //   const Center(
            //     child: Text('التسجيل في الدورات متاح للخريجين فقط.', style: TextStyle(fontSize: 16, color: Colors.orange)),
            //   )
            else if (isAlreadyEnrolled) // إذا كان مسجل بالفعل (ومصادق عليه)
              const Center(
                child: Text('أنت مسجل بالفعل في هذه الدورة.', style: TextStyle(fontSize: 16, color: Colors.green)),
              )
            else if (isEnrolling) // إذا كان يتم عملية التسجيل حالياً
                const Center(child: CircularProgressIndicator())
              else // إذا لم يكن مسجل بالفعل وليس في عملية تسجيل (ومصادق عليه ونوعه مناسب)
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