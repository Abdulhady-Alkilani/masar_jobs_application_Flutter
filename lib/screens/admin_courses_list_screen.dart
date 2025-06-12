import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_course_provider.dart'; // لتنفيذ عمليات CRUD
import '../models/training_course.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO المطلوبة
import 'admin_course_detail_screen.dart'; // شاشة التفاصيل
import 'create_edit_course_screen.dart'; // <--- شاشة إضافة/تعديل الدورة


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
    // جلب قائمة الدورات عند تهيئة الشاشة
    Provider.of<AdminCourseProvider>(context, listen: false).fetchAllCourses(context);

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق من أن هناك المزيد لتحميله ومن أننا لسنا بصدد جلب بالفعل
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !Provider.of<AdminCourseProvider>(context, listen: false).isFetchingMore &&
          Provider.of<AdminCourseProvider>(context, listen: false).hasMorePages) {
        Provider.of<AdminCourseProvider>(context, listen: false).fetchMoreCourses(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // تابع لحذف دورة
  Future<void> _deleteCourse(int courseId) async {
    // يمكن إضافة حالة تحميل خاصة هنا إذا أردت (في Stateful Widget)
    // setState(() { _isDeleting = true; }); // مثال

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه الدورة؟'), // يمكنك عرض اسم الدورة هنا إذا كان متاحاً بسهولة
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه
      final provider = Provider.of<AdminCourseProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteCourse(context, courseId);
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الدورة بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الدورة: ${e.toString()}')),
        );
      } finally {
        // setState(() { _isDeleting = false; }); // مثال
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final courseProvider = Provider.of<AdminCourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الدورات'),
        actions: [
          // زر إضافة دورة جديدة
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // الانتقال إلى شاشة إضافة دورة جديدة (CreateEditCourseScreen)
              print('Add Course Tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  // نمرر null لـ course للإشارة إلى أنها شاشة إضافة
                  builder: (context) => const CreateEditCourseScreen(course: null),
                ),
              );
            },
          ),
        ],
      ),
      body: courseProvider.isLoading && courseProvider.courses.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : courseProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${courseProvider.error}'))
          : courseProvider.courses.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لا توجد دورات.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: courseProvider.courses.length + (courseProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == courseProvider.courses.length) {
            // إذا كنا في حالة جلب المزيد، اعرض مؤشر
            return courseProvider.isFetchingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(); // وإلا لا تعرض شيئاً
          }

          final course = courseProvider.courses[index];
          // تأكد أن الدورة لديها ID قبل عرض أزرار التعديل/الحذف أو الانتقال
          if (course.courseId == null) return const SizedBox.shrink();

          return ListTile(
            title: Text(course.courseName ?? 'بدون عنوان'),
            subtitle: Text('الناشر UserID: ${course.userId ?? 'غير محدد'} - المستوى: ${course.stage ?? ''} - الشهادة: ${course.certificate ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر تعديل دورة
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: courseProvider.isLoading ? null : () { // تعطيل الزر أثناء تحميل أي عملية في Provider
                    // الانتقال إلى شاشة تعديل دورة
                    print('Edit Course Tapped for ID ${course.courseId}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // نمرر كائن الدورة لـ CreateEditCourseScreen للإشارة إلى أنها شاشة تعديل
                        builder: (context) => CreateEditCourseScreen(course: course),
                      ),
                    );
                  },
                ),
                // زر حذف دورة
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: courseProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                    _deleteCourse(course.courseId!); // استدعاء تابع الحذف
                  },
                ),
              ],
            ),
            onTap: courseProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
              // الانتقال لتفاصيل الدورة
              print('Course Tapped: ${course.courseId}');
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