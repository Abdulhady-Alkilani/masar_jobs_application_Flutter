import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_enrollments_provider.dart';
import '../models/enrollment.dart';
import '../models/training_course.dart'; // needed for nested course
import 'training_course_detail_screen.dart'; // لعرض تفاصيل الدورة المرتبطة

class MyEnrollmentsScreen extends StatefulWidget {
  const MyEnrollmentsScreen({Key? key}) : super(key: key);

  @override
  _MyEnrollmentsScreenState createState() => _MyEnrollmentsScreenState();
}

class _MyEnrollmentsScreenState extends State<MyEnrollmentsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<MyEnrollmentsProvider>(context, listen: false).fetchMyEnrollments(context);
  }

  Future<void> _deleteEnrollment(int enrollmentId) async {
    final enrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context, listen: false);
    try {
      await enrollmentsProvider.deleteEnrollment(context, enrollmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء التسجيل بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إلغاء التسجيل: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
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
        itemCount: enrollmentsProvider.enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = enrollmentsProvider.enrollments[index];
          return ListTile(
            title: Text(enrollment.trainingCourse?.courseName ?? 'دورة غير معروفة'),
            subtitle: Text('الحالة: ${enrollment.status ?? 'غير محدد'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // TODO: إضافة تأكيد قبل الحذف
                _deleteEnrollment(enrollment.enrollmentId!);
              },
            ),
            onTap: () {
              // TODO: الانتقال إلى شاشة تفاصيل التسجيل أو تفاصيل الدورة المرتبطة
              if (enrollment.courseId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingCourseDetailScreen(courseId: enrollment.courseId!),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}