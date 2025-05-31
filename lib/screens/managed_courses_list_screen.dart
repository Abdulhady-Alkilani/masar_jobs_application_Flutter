import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_training_course_provider.dart'; // يستخدمه كل من المدير والاستشاري
import '../models/training_course.dart';
import 'managed_course_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة دورة جديدة


class ManagedCoursesListScreen extends StatefulWidget {
  // يمكن تمرير نوع المستخدم هنا إذا كان السلوك مختلفاً قليلاً للمدير/الاستشاري
  // final String userType;
  const ManagedCoursesListScreen({Key? key}) : super(key: key);

  @override
  _ManagedCoursesListScreenState createState() => _ManagedCoursesListScreenState();
}

class _ManagedCoursesListScreenState extends State<ManagedCoursesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<ManagedTrainingCourseProvider>(context, listen: false).fetchManagedCourses(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<ManagedTrainingCourseProvider>(context, listen: false).fetchMoreManagedCourses(context);
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
    final courseProvider = Provider.of<ManagedTrainingCourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دوراتي المنشورة'), // أو 'دورات شركتي المنشورة'
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة دورة جديدة (CreateCourseScreen)
              print('Add Course Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة دورة لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: courseProvider.isLoading && courseProvider.managedCourses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : courseProvider.error != null
          ? Center(child: Text('Error: ${courseProvider.error}'))
          : courseProvider.managedCourses.isEmpty
          ? const Center(child: Text('لم تنشر أي دورات بعد.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: courseProvider.managedCourses.length + (courseProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == courseProvider.managedCourses.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final course = courseProvider.managedCourses[index];
          return ListTile(
            title: Text(course.courseName ?? 'بدون عنوان'),
            subtitle: Text('${course.site ?? ''} - ${course.stage ?? ''} (${course.certificate ?? ''})'),
            trailing: Text(course.startDate?.toString().split(' ')[0] ?? ''),
            onTap: () {
              // الانتقال لتفاصيل الدورة (للمدير/الاستشاري)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagedCourseDetailScreen(courseId: course.courseId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateCourseScreen لإضافة دورة جديدة (ستحتاج ManagedTrainingCourseProvider.createCourse)