// lib/screens/admin/courses/admin_courses_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../../providers/admin_course_provider.dart';
import '../../../models/training_course.dart';
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator
// TODO: قم باستيراد شاشة تفاصيل الدورة للأدمن وشاشة إضافة/تعديل الدورة
// import 'admin_course_details_screen.dart';
// import 'admin_create_edit_course_screen.dart';


class AdminCoursesListScreen extends StatefulWidget {
  const AdminCoursesListScreen({super.key});

  @override
  State<AdminCoursesListScreen> createState() => _AdminCoursesListScreenState();
}

class _AdminCoursesListScreenState extends State<AdminCoursesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب الصفحة الأولى عند تهيئة الشاشة لأول مرة
    final provider = Provider.of<AdminCourseProvider>(context, listen: false);

    // تأكد من أن القائمة فارغة قبل الجلب
    if (provider.courses.isEmpty) {
      provider.fetchAllCourses(context);
    }

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق مما إذا كان المستخدم قد وصل إلى نهاية القائمة تقريباً
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95) {
        // تحقق مما إ��ا كان هناك المزيد من الصفحات للجلب وأننا لا نجلب حالياً
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreCourses(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // تنظيف الـ controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم Consumer للاستماع إلى تغييرات AdminCourseProvider وإعادة بناء الواجهة
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الدورات التدريبية (أدمن)'),
      ),
      body: Consumer<AdminCourseProvider>(
        builder: (context, provider, child) {
          // عرض مؤشر تحميل إذا كانت القائمة فارغة ويتم تحميلها لأول مرة
          if (provider.isLoading && provider.courses.isEmpty) {
            return const Center(child: RiveLoadingIndicator());
          }

          // عرض رسالة خطأ إذا حدث خطأ والقائمة فارغة
          if (provider.error != null && provider.courses.isEmpty) {
            return Center(child: Text('حدث خطأ: ${provider.error}'));
          }

          // عرض رسالة إذا كانت القائمة فارغة بعد التحميل
          if (provider.courses.isEmpty) {
            return const Center(child: Text('لا توجد دورات تدريبية متاحة للإدارة حالياً.'));
          }

          // عرض القائمة مع إمكانية السحب للتحديث
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllCourses(context), // عند السحب للأسفل، قم بجلب الصفحة الأولى مجدداً
            child: ListView.builder(
              controller: _scrollController, // ربط الـ controller بالتمرير
              itemCount: provider.courses.length + (provider.isFetchingMore ? 1 : 0), // +1 لعرض مؤشر التحميل في نهاية القائمة
              itemBuilder: (context, index) {
                // إذا وصلنا إلى العنصر الأخير وكان هناك جلب للمزيد، اعرض مؤشر التحميل
                if (index == provider.courses.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: RiveLoadingIndicator()),
                  );
                }

                // عرض بطاقة الدورة التدريبية
                final course = provider.courses[index];
                return _buildCourseCard(context, course, provider);
              },
            ),
          );
        },
      ),
      // زر عائم لإضافة دورة جديدة
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: الانتقال إلى شاشة إضافة دورة جديدة
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEditCourseScreen()));
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة دورة تدريبية جديدة',
      ),
    );
  }

  // بناء بطاقة عرض الدورة التدريبية
  Widget _buildCourseCard(BuildContext context, TrainingCourse course, AdminCourseProvider provider) {
    // TODO: أضف حقل صورة للدورة التدريبية في الموديل والـ API إذا كان متاحاً
    // const String baseUrl = 'https://your-base-url.com';
    // final imageUrl = (course.coursePhoto != null && course.coursePhoto!.isNotEmpty)
    //     ? baseUrl + course.coursePhoto!
    //     : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // TODO: الانتقال إلى شاشة تفاصيل الدورة للأدمن (قد تسمح بالتعديل والمتابعة)
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCourseDetailsScreen(courseId: course.courseId!)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.courseName ?? 'بدون عنوان',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                course.courseDescription ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.trainersName ?? 'غير محدد المدرب',
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.site ?? 'غير محدد الموقع',
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.stage ?? 'غير محدد المستوى',
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.card_membership_outlined, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'شهادة: ${course.certificate ?? 'غير محدد'}',
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // أزرار التعديل والحذف
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'تعديل',
                    onPressed: () {
                      // TODO: الانتقال إلى شاشة تعديل الدورة
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCreateEditCourseScreen(course: course)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: () async {
                      // تأكيد الحذف قبل المتابعة
                      final bool? confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تأكيد الحذف'),
                          content: const Text('هل أنت متأكد أنك تريد حذف هذه الدورة؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('حذف'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true && course.courseId != null) {
                        try {
                          // استدعاء تابع الحذف من Provider
                          await provider.deleteCourse(context, course.courseId!);
                          // عرض رسالة نجاح (اختياري)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف الدورة بنجاح')),
                          );
                        } catch (e) {
                          // التعامل مع الخطأ إذا لم يتمكن Provider من الحذف
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل حذف الدورة: ${provider.error}')),
                          );
                        }
                      }
                    },
                  ),
                  // عرض رابط التسجيل إذا كان موجوداً
                  if (course.enrollHyperLink != null && course.enrollHyperLink!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.link, color: Colors.green),
                      tooltip: 'رابط التسجيل',
                      onPressed: () {
                        // TODO: فتح الرابط في متصفح خارجي
                        // launch(course.enrollHyperLink!); // ستحتاج إلى استيراد url_launcher
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// يمكنك إبقاء هذا الـ Extension هنا أو نقله إلى ملف Extensions مشترك
extension ListTrainingCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}