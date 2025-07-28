// lib/screens/public_views/public_course_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/training_course.dart';
import '../../providers/my_enrollments_provider.dart';
import '../../providers/public_training_course_provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../../widgets/rive_loading_indicator.dart';

class PublicCourseDetailsScreen extends StatefulWidget {
  final int courseId;
  const PublicCourseDetailsScreen({super.key, required this.courseId});

  @override
  State<PublicCourseDetailsScreen> createState() => _PublicCourseDetailsScreenState();
}

class _PublicCourseDetailsScreenState extends State<PublicCourseDetailsScreen> {
  late Future<TrainingCourse?> _courseFuture;

  @override
  void initState() {
    super.initState();
    _courseFuture = Provider.of<PublicTrainingCourseProvider>(context, listen: false).fetchTrainingCourse(widget.courseId);
  }

  void _enrollInCourse(TrainingCourse course) async {
    final myEnrollmentsProvider = Provider.of<MyEnrollmentsProvider>(context, listen: false);
    try {
      await myEnrollmentsProvider.enrollInCourse(context, course.courseId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيلك في الدورة بنجاح!'), backgroundColor: Colors.green),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التسجيل: ${e.message}'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: FutureBuilder<TrainingCourse?>(
        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'خطأ',
              message: 'تعذر ��حميل تفاصيل الدورة. يرجى المحاولة مرة أخرى.',
              onRefresh: () {
                setState(() {
                  _courseFuture = Provider.of<PublicTrainingCourseProvider>(context, listen: false).fetchTrainingCourse(widget.courseId);
                });
              },
            );
          }

          final course = snapshot.data!;
          final bool isCourseEnded = course.endDate != null && course.endDate!.isBefore(DateTime.now());

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.white, // AppBar background white
                iconTheme: IconThemeData(color: theme.primaryColor), // Icons in primary color
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  title: Text(
                    course.courseName ?? 'تفاصيل الدورة',
                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.3))]),
                    textAlign: TextAlign.center,
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xFFE0F7FA)], // White to light sky blue gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(Icons.school_outlined, color: theme.primaryColor.withOpacity(0.2), size: 150),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(theme, course).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        _buildSection(theme, 'وصف الدورة', course.courseDescription, isDescription: true).animate().fadeIn(delay: 300.ms),
                        _buildSkillsSection(theme, 'المهارات المكتسبة', course.skills).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 40),
                        if (authProvider.isAuthenticated)
                          Center(
                            child: ElevatedButton.icon(
                              icon: Icon(isCourseEnded ? Icons.lock_clock_outlined : Icons.app_registration_rounded),
                              label: Text(isCourseEnded ? 'الدورة منتهية' : 'التسجيل في الدورة'),
                              onPressed: isCourseEnded ? null : () => _enrollInCourse(course),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                disabledBackgroundColor: Colors.grey.shade400,
                                disabledForegroundColor: Colors.white,
                              ),
                            ).animate(delay: 500.ms).scale(duration: 500.ms, curve: Curves.elasticOut),
                          ),
                      ],
                    ),
                  )
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, TrainingCourse course) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow(theme, Icons.person_pin_circle_outlined, 'المدرب', course.trainersName ?? 'غير معروف'),
            _buildInfoRow(theme, Icons.business_outlined, 'الجهة التدريبية', course.trainersSite ?? 'غير محدد'),
            _buildInfoRow(theme, Icons.location_on_outlined, 'الموقع', course.site ?? 'أونلاين'),
            _buildInfoRow(theme, Icons.bar_chart_outlined, 'المستوى', course.stage ?? 'مبتدئ'),
            _buildInfoRow(theme, Icons.calendar_today_outlined, 'التاريخ',
              '${course.startDate != null ? DateFormat('d MMMM', 'ar').format(course.startDate!) : ''} - ${course.endDate != null ? DateFormat('d MMMM yyyy', 'ar').format(course.endDate!) : ''}',
            ),
            _buildInfoRow(theme, Icons.workspace_premium_outlined, 'شهادة', course.certificate ?? 'لا يوجد', noDivider: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value, {bool noDivider = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 22),
            const SizedBox(width: 16),
            Text('$label:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis)),
          ],
        ),
        if (!noDivider) const Divider(height: 28),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, String? content, {bool isDescription = false}) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, title),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.7, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme, String title, String? skills) {
    final skillList = skills?.split(',').where((s) => s.trim().isNotEmpty).toList() ?? [];
    if (skillList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, title),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: skillList.map((skill) => Chip(
              label: Text(skill.trim()),
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            )).toList(),
          ),
        ],
      ),
    );
  }
}