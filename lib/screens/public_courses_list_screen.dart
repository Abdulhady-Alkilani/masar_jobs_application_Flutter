import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_training_course_provider.dart'; // تأكد من المسار
import '../models/training_course.dart'; // تأكد من المسار
import 'training_course_detail_screen.dart'; // تأكد من المسار (شاشة تفاصيل الدورة العامة)

class PublicCoursesListScreen extends StatefulWidget {
  const PublicCoursesListScreen({Key? key}) : super(key: key);

  @override
  _PublicCoursesListScreenState createState() => _PublicCoursesListScreenState();
}

class _PublicCoursesListScreenState extends State<PublicCoursesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب قائمة الدورات عند تهيئة الشاشة
    Provider.of<PublicTrainingCourseProvider>(context, listen: false).fetchTrainingCourses();

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // المستخدم وصل لنهاية القائمة، جلب المزيد
        Provider.of<PublicTrainingCourseProvider>(context, listen: false).fetchMoreTrainingCourses();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final courseProvider = Provider.of<PublicTrainingCourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدورات التدريبية'),
      ),
      body: courseProvider.isLoading && courseProvider.courses.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : courseProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${courseProvider.error}'))
          : courseProvider.courses.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لا توجد دورات متاحة حالياً.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: courseProvider.courses.length + (courseProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == courseProvider.courses.length) {
            return const Center(child: CircularProgressIndicator());
          }

          // عرض بيانات الدورة
          final course = courseProvider.courses[index];
          return ListTile(
            title: Text(course.courseName ?? 'بدون عنوان'),
            subtitle: Text('${course.stage ?? ''} - ${course.site ?? ''}'), // مثال: مبتدئ - اونلاين
            trailing: Text(course.startDate?.toString().split(' ')[0] ?? ''), // عرض تاريخ البداية
            onTap: () {
              // الانتقال إلى شاشة تفاصيل الدورة
              if (course.courseId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingCourseDetailScreen(courseId: course.courseId!),
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