// lib/screens/public_views/PublicTrainingCoursesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/public_training_course_provider.dart';
import '../../models/training_course.dart';

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
    // ... معالجة الأخطاء والفراغ ...

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.courses.length,
      itemBuilder: (context, index) {
        final course = provider.courses[index];
        return CourseCard(course: course)
            .animate(delay: (100 * (index % 10)).ms)
            .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic)
            .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.1));
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ويدجت البطاقة المخصصة
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
        transform: _isHovered ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isHovered
                ? [theme.primaryColor, theme.colorScheme.secondary]
                : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? theme.primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.08),
              blurRadius: _isHovered ? 20 : 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.courseName ?? 'عنوان الدورة غير معروف',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isHovered ? Colors.white : theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: _isHovered ? Colors.white70 : Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'المدرب: ${widget.course.trainersName ?? 'غير معروف'}',
                          style: TextStyle(color: _isHovered ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'المهارات المكتسبة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isHovered ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: (widget.course.skills?.split(',') ?? [])
                          .map((skill) => Chip(
                        label: Text(skill.trim(), style: TextStyle(color: _isHovered ? theme.primaryColor : Colors.white)),
                        backgroundColor: _isHovered ? Colors.white.withOpacity(0.9) : theme.primaryColor.withOpacity(0.8),
                      ))
                          .toList(),
                    ),
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