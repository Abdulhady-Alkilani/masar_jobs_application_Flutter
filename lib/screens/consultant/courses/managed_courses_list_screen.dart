// lib/screens/consultant/courses/managed_courses_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/managed_training_course_provider.dart';
import '../../../models/training_course.dart';
import '../../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_edit_course_screen.dart';

class ManagedCoursesListScreen extends StatefulWidget {
  const ManagedCoursesListScreen({super.key});
  @override
  State<ManagedCoursesListScreen> createState() => _ManagedCoursesListScreenState();
}

class _ManagedCoursesListScreenState extends State<ManagedCoursesListScreen> {
  // --- هنا تم تعريف الـ Controller المفقود ---
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);
    provider.fetchManagedCourses(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreManagedCourses(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // <-- التخلص منه هنا
    super.dispose();
  }

  // --- هنا تم تعريف دالة الحذف المفقودة ---
  Future<void> _deleteCourse(TrainingCourse course, ManagedTrainingCourseProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف دورة "${course.courseName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && mounted) {
      try {
        await provider.deleteCourse(context, course.courseId!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الدورة بنجاح'), backgroundColor: Colors.green));
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة دوراتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة دورة جديدة',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditCourseScreen()));
            },
          ),
        ],
      ),
      body: Consumer<ManagedTrainingCourseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.managedCourses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.managedCourses.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'حدث خطأ',
              message: 'لم نتمكن من جلب دوراتك. حاول تحديث الصفحة.',
              onRefresh: () => provider.fetchManagedCourses(context),
            );
          }
          if (provider.managedCourses.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.school_outlined,
              title: 'ابدأ بتعليم الآخرين',
              message: 'لم تقم بنشر أي دورات بعد. اضغط على زر الإضافة لإنشاء دورتك الأولى.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchManagedCourses(context),
            child: ListView.builder(
              controller: _scrollController, // <-- هنا يتم استخدامه
              padding: const EdgeInsets.all(16),
              itemCount: provider.managedCourses.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.managedCourses.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                final course = provider.managedCourses[index];
                return _buildCourseCard(course, provider)
                    .animate(delay: (100 * (index % 10)).ms)
                    .fadeIn()
                    .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(TrainingCourse course, ManagedTrainingCourseProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          child: Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(course.courseName ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('المدرب: ${course.trainersName ?? 'غير معروف'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditCourseScreen(course: course)));
            } else if (value == 'delete') {
              _deleteCourse(course, provider); // <-- هنا يتم استدعاؤها
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}