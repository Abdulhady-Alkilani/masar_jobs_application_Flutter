// lib/screens/public_views/PublicTrainingCoursesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/public_training_course_provider.dart';
import '../../models/training_course.dart';
import '../widgets/empty_state_widget.dart';
// استيراد شاشة تفاصيل الدورة الجديدة
import 'public_training_course_details_screen.dart';


class PublicTrainingCoursesScreen extends StatefulWidget {
  const PublicTrainingCoursesScreen({super.key});
  @override
  State<PublicTrainingCoursesScreen> createState() => _PublicTrainingCoursesScreenState();
}

class _PublicTrainingCoursesScreenState extends State<PublicTrainingCoursesScreen> with AutomaticKeepAliveClientMixin {
  // إضافة ScrollController لدعم التمرير اللانهائي
  final ScrollController _scrollController = ScrollController();


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicTrainingCourseProvider>(context, listen: false);
      // جلب الصفحة الأولى فقط إذا كانت القائمة فارغة لتجنب إعادة الجلب غير الضرورية عند العودة للشاشة
      if (p.courses.isEmpty) {
        p.fetchTrainingCourses();
      }
      // TODO: قد تحتاج إلى إعادة جلب القائمة إذا مر وقت طويل منذ آخر جلب أو بناءً على حدث معين
    });

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق مما إذا كان المستخدم قد وصل إلى نهاية القائمة تقريباً (مثلاً، آخر 200 بكسل)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // تحقق مما إذا كان هناك المزيد من الصفحات للجلب وأننا لا نجلب حالياً
        final provider = Provider.of<PublicTrainingCourseProvider>(context, listen: false);
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreTrainingCourses();
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
    super.build(context);
    final provider = context.watch<PublicTrainingCourseProvider>(); // استخدم watch للاستماع للتغييرات

    // عرض مؤشر تحميل إذا كانت القائمة فارغة ويتم تحميلها لأول مرة
    if (provider.isLoading && provider.courses.isEmpty) return _buildShimmerLoading();

    // عرض رسالة خطأ إذا حدث خطأ والقائمة فارغة
    if (provider.error != null && provider.courses.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'حدث خطأ ما',
        message: 'لم نتمكن من جلب الدورات. يرجى المحاولة مرة أخرى.',
        onRefresh: () => provider.fetchTrainingCourses(),
      );
    }

    // عرض رسالة إذا كانت القائمة فارغة بعد التحميل
    if (provider.courses.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.school_outlined,
        title: 'لا توجد دورات متاحة',
        message: 'نعمل على إضافة المزيد من الدورات التدريبية المميزة قريباً. ترقب!',
      );
    }

    // عرض القائمة مع إمكانية السحب للتحديث
    return RefreshIndicator(
      onRefresh: () => provider.fetchTrainingCourses(), // عند السحب للأسفل، قم بجلب الصفحة الأولى مجدداً
      child: ListView.builder(
        controller: _scrollController, // ربط الـ controller بالتمرير
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: provider.courses.length + (provider.isFetchingMore ? 1 : 0), // +1 لعرض مؤشر التحميل في نهاية القائمة
        itemBuilder: (context, index) {
          // إذا وصلنا إلى العنصر الأخير وكان هناك جلب للمزيد، اعرض مؤشر التحميل
          if (index == provider.courses.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // عرض بطاقة الدورة التدريبية
          final course = provider.courses[index];
          return CourseCard(course: course)
          // إضافة تأثيرات الحركة عند ظهور العنصر
              .animate(delay: (120 * (index % 10)).ms)
              .fadeIn(duration: 800.ms)
              .slideX(begin: 0.2, duration: 800.ms, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  // بناء شاشة تحميل وهمية (Shimmer)
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: 5, // عدد العناصر الوهمية
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 160, // ارتفاع تقريبي لبطاقة الدورة
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

// بطاقة عرض الدورة التدريبية
class CourseCard extends StatefulWidget {
  final TrainingCourse course;
  const CourseCard({Key? key, required this.course}) : super(key: key);
  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        transform: _isHovered ? (Matrix4.identity()..translate(0.0, -8.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? theme.colorScheme.secondary : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? theme.colorScheme.secondary.withOpacity(0.15) : Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // !!! التعديل هنا !!!
              onTap: () {
                // الانتقال إلى شاشة تفاصيل الدورة عند النقر
                // نمرر courseId للشاشة الجديدة لتجلب التفاصيل بنفسها
                if (widget.course.courseId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicCourseDetailsScreen(courseId: widget.course.courseId!),
                    ),
                  );
                } else {
                  // التعامل مع حالة عدم وجود معرف للدورة (غير متوقع)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا يمكن عرض تفاصيل هذه الدورة')),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.courseName ?? 'عنوان الدورة غير معروف',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'المدرب: ${widget.course.trainersName ?? 'غير معروف'}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'المهارات المكتسبة:',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // TODO: تحليل حقل skills إذا كان نصياً معقداً (JSON أو تنسيق آخر غير بسيط)
                    // حالياً يفترض أنه نص بسيط أو مفصول بفواصل
                    if (widget.course.skills != null && widget.course.skills!.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: (widget.course.skills!.split(',')) // تقسيم المهارات حسب الفاصلة
                            .map((skill) => Chip(
                          label: Text(skill.trim()), // إزالة المسافات الزائدة
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                        ))
                            .toList(),
                      )
                    else
                      Text('لا توجد مهارات محددة', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),

                    const SizedBox(height: 16),

                    // عرض رابط التسجيل مباشرة في البطاقة إذا أردت
                    //  if (widget.course.enrollHyperLink != null && widget.course.enrollHyperLink!.isNotEmpty)
                    //     TextButton.icon(
                    //       icon: Icon(Icons.link),
                    //       label: Text('رابط التسجيل'),
                    //       onPressed: () {
                    //         // TODO: فتح الرابط
                    //       },
                    //     ),

                  ],
                ),
              ),
            ),
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