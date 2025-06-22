// lib/screens/manager/managed_courses_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/managed_training_course_provider.dart';
import '../../models/training_course.dart';
import 'create_edit_course_screen.dart'; // شاشة لإنشاء/تعديل دورة
import 'course_enrollees_screen.dart'; // شاشة لعرض المسجلين

class ManagedCoursesListScreen extends StatefulWidget {
  const ManagedCoursesListScreen({super.key});

  @override
  State<ManagedCoursesListScreen> createState() => _ManagedCoursesListScreenState();
}

class _ManagedCoursesListScreenState extends State<ManagedCoursesListScreen> {
  @override
  void initState() {
    super.initState();
    // جلب الدورات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManagedTrainingCourseProvider>(context, listen: false).fetchManagedCourses(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ManagedTrainingCourseProvider>(
        builder: (context, courseProvider, child) {
          if (courseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseProvider.error != null) {
            return Center(child: Text('خطأ: ${courseProvider.error}'));
          }

          if (courseProvider.managedCourses.isEmpty) {
            return const Center(
              child: Text(
                'لم تقم بإضافة أي دورات تدريبية بعد.\nاضغط على زر + للبدء.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => courseProvider.fetchManagedCourses(context),
            child: ListView.builder(
              itemCount: courseProvider.managedCourses.length,
              itemBuilder: (context, index) {
                final course = courseProvider.managedCourses[index];
                return _buildCourseCard(context, course, courseProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // الانتقال لشاشة إنشاء دورة جديدة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditCourseScreen(),
            ),
          );
        },
        tooltip: 'إضافة دورة تدريبية جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, TrainingCourse course, ManagedTrainingCourseProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // عرض المسجلين في هذه الدورة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseEnrolleesScreen(courseId: course.courseId!, courseTitle: course.site ?? ''),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course.site ?? 'بدون عنوان',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEditCourseScreen(course: course),
                          ),
                        );
                      } else if (value == 'delete') {
                        // TODO: إضافة منطق تأكيد الحذف المشابه لمنطق الوظائف
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(course.site ?? 'غير محدد'),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${course.hours ?? 0} ساعات'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  // TODO: عرض عدد المسجلين إذا كان متاحاً في الموديل
                  const Text(' 12 مسجل'), // مثال
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}