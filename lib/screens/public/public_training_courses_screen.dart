// lib/screens/public_views/PublicTrainingCoursesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/public_training_course_provider.dart';
import '../../models/training_course.dart';
import '../widgets/empty_state_widget.dart';

class PublicTrainingCoursesScreen extends StatefulWidget {
  const PublicTrainingCoursesScreen({super.key});
  @override
  State<PublicTrainingCoursesScreen> createState() => _PublicTrainingCoursesScreenState();
}

class _PublicTrainingCoursesScreenState extends State<PublicTrainingCoursesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicTrainingCourseProvider>(context, listen: false);
      if (p.courses.isEmpty) p.fetchTrainingCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<PublicTrainingCourseProvider>();

    if (provider.isLoading && provider.courses.isEmpty) return _buildShimmerLoading();
    if (provider.error != null && provider.courses.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'حدث خطأ ما',
        message: 'لم نتمكن من جلب الدورات. يرجى المحاولة مرة أخرى.',
        onRefresh: () => provider.fetchTrainingCourses(),
      );
    }
    if (provider.courses.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.school_outlined,
        title: 'لا توجد دورات متاحة',
        message: 'نعمل على إضافة المزيد من الدورات التدريبية المميزة قريباً. ترقب!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchTrainingCourses(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: provider.courses.length,
        itemBuilder: (context, index) {
          final course = provider.courses[index];
          return CourseCard(course: course)
              .animate(delay: (120 * (index % 10)).ms)
              .fadeIn(duration: 800.ms)
              .slideX(begin: 0.2, duration: 800.ms, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 160,
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
              onTap: () {},
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
                    if (widget.course.skills != null && widget.course.skills!.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: (widget.course.skills!.split(','))
                            .map((skill) => Chip(
                          label: Text(skill.trim()),
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                        ))
                            .toList(),
                      )
                    else
                      Text('لا توجد مهارات محددة', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
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