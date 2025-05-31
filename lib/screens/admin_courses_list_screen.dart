import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_course_provider.dart'; // تأكد من المسار
import '../models/training_course.dart'; // تأكد من المسار
import 'admin_course_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة/تعديل دورة


class AdminCoursesListScreen extends StatefulWidget {
  const AdminCoursesListScreen({Key? key}) : super(key: key);

  @override
  _AdminCoursesListScreenState createState() => _AdminCoursesListScreenState();
}

class _AdminCoursesListScreenState extends State<AdminCoursesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<AdminCourseProvider>(context, listen: false).fetchAllCourses(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<AdminCourseProvider>(context, listen: false).fetchMoreCourses(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // TODO: تابع لحذف دورة (adminCourseProvider.deleteCourse) مع تأكيد

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<AdminCourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الدورات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة دورة جديدة (CreateEditCourseScreen)
              print('Add Course Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة دورة لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: courseProvider.isLoading && courseProvider.courses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : courseProvider.error != null
          ? Center(child: Text('Error: ${courseProvider.error}'))
          : courseProvider.courses.isEmpty
          ? const Center(child: Text('لا توجد دورات.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: courseProvider.courses.length + (courseProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == courseProvider.courses.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final course = courseProvider.courses[index];
          return ListTile(
            title: Text(course.courseName ?? 'بدون عنوان'),
            subtitle: Text('الناشر UserID: ${course.userId ?? 'غير محدد'} - المستوى: ${course.stage ?? ''} - الشهادة: ${course.certificate ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: () {
                    // TODO: الانتقال إلى شاشة تعديل دورة (CreateEditCourseScreen) مع تمرير بيانات الدورة
                    print('Edit Course Tapped for ID ${course.courseId}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة تعديل دورة لم تنفذ.')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: () {
                    if (course.courseId != null) {
                      // TODO: تابع لحذف الدورة (adminCourseProvider.deleteCourse) مع تأكيد
                      print('Delete Course Tapped for ID ${course.courseId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('وظيفة حذف دورة لم تنفذ.')),
                      );
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              // الانتقال لتفاصيل الدورة
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminCourseDetailScreen(courseId: course.courseId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateEditCourseScreen لإضافة أو تعديل دورة (تحتاج AdminCourseProvider.createCourse و .updateCourse)
// TODO: أنشئ شاشة AdminCourseDetailScreen لعرض تفاصيل دورة (تحتاج AdminCourseProvider.fetchCourse أو استخدام public fetch)