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

  // دالة التسجيل في الدورة
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<TrainingCourse?>(
        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'خطأ',
              message: 'تعذر تحميل تفاصيل الدورة. يرجى المحاولة مرة أخرى.',
              onRefresh: () {
                setState(() {
                  _courseFuture = Provider.of<PublicTrainingCourseProvider>(context, listen: false).fetchTrainingCourse(widget.courseId);
                });
              },
            );
          }

          final course = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // 1. الشريط العلوي (Header)
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                stretch: true,
                backgroundColor: theme.primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  title: Text(
                    course.courseName ?? 'تفاصيل الدورة',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, theme.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.school_outlined, color: Colors.white24, size: 150),
                  ),
                ),
              ),

              // 2. محتوى الصفحة
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(theme, course).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        _buildSection(theme, 'وصف الدورة', course.description, isDescription: true).animate().fadeIn(delay: 300.ms),
                        _buildSkillsSection(theme, 'المهارات المكتسبة', course.skills).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                        const SizedBox(height: 40),
                        if (authProvider.isAuthenticated)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.app_registration_rounded),
                              label: const Text('التسجيل في الدورة'),
                              onPressed: () => _enrollInCourse(course),
                              style: theme.elevatedButtonTheme.style?.copyWith(
                                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
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

  // --- دوال مساعدة لتنظيم الكود ---
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor));
  }

  Widget _buildInfoCard(ThemeData theme, TrainingCourse course) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(theme, Icons.person_pin_circle_outlined, 'المدرب', course.trainersName ?? 'غير معروف'),
            _buildInfoRow(theme, Icons.business_outlined, 'الجهة التدريبية', course.trainersSite ?? 'غير محدد'),
            _buildInfoRow(theme, Icons.location_on_outlined, 'الموقع', course.site ?? 'أونلاين'),
            _buildInfoRow(theme, Icons.bar_chart_outlined, 'المستوى', course.stage ?? 'مبتدئ'),
            _buildInfoRow(theme, Icons.calendar_today_outlined, 'التاريخ',
              '${course.startDate != null ? DateFormat('dd/MM', 'ar').format(course.startDate!) : ''} - ${course.endDate != null ? DateFormat('dd/MM/yyyy', 'ar').format(course.endDate!) : ''}',
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
            Icon(icon, color: theme.primaryColor, size: 20),
            const SizedBox(width: 16),
            Text('$label:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis)),
          ],
        ),
        if (!noDivider) const Divider(height: 24),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, String? content, {bool isDescription = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, title),
          const SizedBox(height: 8),
          Text(
            content ?? (isDescription ? 'لا يوجد وصف.' : 'غير محدد.'),
            style: theme.textTheme.bodyLarge?.copyWith(height: isDescription ? 1.7 : 1.4, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme, String title, String? skills) {
    final skillList = skills?.split(',').where((s) => s.trim().isNotEmpty).toList() ?? [];
    if (skillList.isEmpty) return const SizedBox.shrink(); // لا تعرض القسم إذا لم تكن هناك مهارات

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(theme, title),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: skillList.map((skill) => Chip(
              label: Text(skill.trim(), style: TextStyle(color: theme.primaryColor)),
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              side: BorderSide.none,
            )).toList(),
          ),
        ],
      ),
    );
  }
}