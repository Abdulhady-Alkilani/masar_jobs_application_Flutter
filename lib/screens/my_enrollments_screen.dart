import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_enrollments_provider.dart'; // لجلب وحذف التسجيلات
import '../models/enrollment.dart'; // تأكد من المسار
import '../models/training_course.dart'; // needed for nested course
import '../services/api_service.dart'; // لاستخدام ApiException


// استيراد شاشات أخرى إذا كنت ستعرض تفاصيل التسجيل أو الدورة من هنا
import 'training_course_detail_screen.dart'; // لعرض تفاصيل الدورة المرتبطة
// TODO: يمكنك إضافة شاشة تفاصيل تسجيل دورة إذا أردت عرض تفاصيل التسجيل نفسه بشكل أوسع


class MyEnrollmentsScreen extends StatefulWidget {
  const MyEnrollmentsScreen({Key? key}) : super(key: key);

  @override
  _MyEnrollmentsScreenState createState() => _MyEnrollmentsScreenState();
}

class _MyEnrollmentsScreenState extends State<MyEnrollmentsScreen> {
  // لا نحتاج ScrollController هنا لأن MyEnrollmentsProvider لا يستخدم Pagination حالياً
  // إذا أضفت Pagination لاحقاً، ستحتاج إضافة ScrollController ومستمع له

  @override
  void initState() {
    super.initState();
    // جلب تسجيلات الدورات الخاصة بالمستخدم عند الدخول للشاشة
    // fetchMyEnrollments يتطلب context
    Provider.of<MyEnrollmentsProvider>(context, listen: false).fetchMyEnrollments(context);
  }

  @override
  void dispose() {
    // إذا أضفت ScrollController، لا تنسى dispose هنا
    super.dispose();
  }

  // تابع لحذف تسجيل
  Future<void> _deleteEnrollment(Enrollment enrollment) async { // تقبل كائن التسجيل بالكامل
    // لا يمكن الحذف بدون معرف التسجيل
    if (enrollment.enrollmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرف التسجيل غير متاح للحذف.')),
      );
      return;
    }

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>( // عرض مربع حوار تأكيد
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد إلغاء التسجيل'),
          content: Text('هل أنت متأكد أنك تريد إلغاء تسجيلك في دورة "${enrollment.trainingCourse?.courseName ?? 'غير معروفة'}"؟'), // عرض اسم الدورة في الرسالة
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }), // إغلاق المربع وإرجاع false
            TextButton(child: const Text('إلغاء التسجيل', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }), // إغلاق المربع وإرجاع true
          ],
        );
      },
    );


    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه (MyEnrollmentsProvider.isLoading)
      final provider = Provider.of<MyEnrollmentsProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteEnrollment(context, enrollment.enrollmentId!); // استدعاء تابع الحذف مع معرف التسجيل
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء التسجيل بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل إلغاء التسجيل: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إلغاء التسجيل: ${e.toString()}')),
        );
      } finally {
        // لا حاجة لتحديث حالة التحميل هنا، Provider سيتكفل بذلك
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final enrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيلات الدورات الخاصة بي'),
      ),
      body: enrollmentsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : enrollmentsProvider.error != null
          ? Center(child: Text('Error: ${enrollmentsProvider.error}'))
          : enrollmentsProvider.enrollments.isEmpty
          ? const Center(child: Text('لم تسجل في أي دورات بعد.'))
          : ListView.builder(
        // لا يوجد ScrollController هنا حالياً
        itemCount: enrollmentsProvider.enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = enrollmentsProvider.enrollments[index];
          // تأكد أن التسجيل لديه ID قبل عرض زر الحذف
          if (enrollment.enrollmentId == null) return const SizedBox.shrink();

          return ListTile(
            title: Text(enrollment.trainingCourse?.courseName ?? 'دورة غير معروفة'),
            subtitle: Text('الحالة: ${enrollment.status ?? 'غير محدد'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: enrollmentsProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                _deleteEnrollment(enrollment); // <--- استدعاء تابع الحذف مع تمرير كائن التسجيل
              },
            ),
            onTap: enrollmentsProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
              // TODO: الانتقال إلى شاشة تفاصيل التسجيل أو تفاصيل الدورة المرتبطة
              // يمكنك اختيار عرض تفاصيل التسجيل نفسه أولاً، أو الانتقال مباشرة لتفاصيل الدورة
              print('Enrollment Tapped: ${enrollment.enrollmentId}');
              // مثال الانتقال لتفاصيل الدورة المرتبطة بالتسجيل
              if (enrollment.courseId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingCourseDetailScreen(courseId: enrollment.courseId!), // <--- الانتقال لشاشة تفاصيل الدورة العامة
                  ),
                );
              } else {
                // إذا لم يكن هناك معرف دورة (حالة غير متوقعة)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('معرف الدورة المرتبطة غير متاح.')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// Simple extension for List<Enrollment> if needed
extension ListEnrollmentExtension on List<Enrollment> {
  Enrollment? firstWhereOrNull(bool Function(Enrollment) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}