// lib/screens/public_views/PublicTrainingCoursesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../providers/public_training_course_provider.dart';
import '../../models/training_course.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/rive_refresh_indicator.dart';
import 'public_training_course_details_screen.dart';

class PublicTrainingCoursesScreen extends StatefulWidget {
  final bool isGuest;
  const PublicTrainingCoursesScreen({super.key, this.isGuest = false});
  @override
  State<PublicTrainingCoursesScreen> createState() => _PublicTrainingCoursesScreenState();
}

class _PublicTrainingCoursesScreenState extends State<PublicTrainingCoursesScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicTrainingCourseProvider>(context, listen: false);
      if (p.courses.isEmpty) {
        p.fetchTrainingCourses();
      }
    });

    _scrollController.addListener(() {
      final provider = Provider.of<PublicTrainingCourseProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreTrainingCourses();
        }
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
    super.build(context);
    final provider = context.watch<PublicTrainingCourseProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.courses.isEmpty) return _buildShimmerLoading();
          if (provider.error != null && provider.courses.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.wifi_off_rounded,
              title: 'أُوпс! حدث خطأ',
              message: 'تعذر تحميل البيانات. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
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

          return RiveRefreshIndicator(
            onRefresh: () => provider.fetchTrainingCourses(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.courses.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.courses.length) {
                  return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                }
                final course = provider.courses[index];
                return CourseCard(course: course)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (100 * (index % 5)).ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const SizedBox(height: 200),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final TrainingCourse course;
  const CourseCard({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = Icons.school_outlined;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 8, // Increased elevation for a more prominent shadow
      shadowColor: Colors.black.withOpacity(0.2), // More visible shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded corners
        side: BorderSide(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (course.courseId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicCourseDetailsScreen(courseId: course.courseId!),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Card Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(iconData, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.trainersName ?? 'جهة تدريبية غير معروفة',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (course.startDate != null)
                          Text(
                            'تبدأ في: ${DateFormat.yMMMd('ar').format(course.startDate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- Card Content ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                course.courseName ?? 'عنوان الدورة غير معروف',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (course.courseDescription != null && course.courseDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  course.courseDescription!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            // --- Card Footer ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    avatar: Icon(Icons.location_on_outlined, size: 16, color: theme.primaryColor),
                    label: Text(course.site ?? 'غير محدد'),
                    backgroundColor: theme.primaryColor.withOpacity(0.05),
                  ),
                  if (course.endDate != null)
                    Chip(
                      avatar: Icon(Icons.event_busy_outlined, size: 16, color: Colors.red.shade700),
                      label: Text('ينتهي في: ${DateFormat('dd/MM/yyyy', 'ar').format(course.endDate!)}'),
                      backgroundColor: Colors.red.withOpacity(0.05),
                    ),
                ],
              ),
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (course.courseId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PublicCourseDetailsScreen(courseId: course.courseId!),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.read_more_outlined),
                    label: const Text('عرض التفاصيل'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}