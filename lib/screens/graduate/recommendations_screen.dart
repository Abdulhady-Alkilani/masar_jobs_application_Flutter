// lib/screens/graduate/recommendations_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../models/job_opportunity.dart';
import '../../models/training_course.dart';
import '../public/job_detail_screen.dart';
import '../public/course_detail_screen.dart';
import '../../widgets/rive_loading_indicator.dart';
import '../widgets/empty_state_widget.dart'; // Import RiveLoadingIndicator

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});
  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    // استخدام addPostFrameCallback لضمان أن الـ context متاح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecommendationProvider>(context, listen: false).fetchRecommendations(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('توصيات مخصصة لك')),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          // --- الحالة 1: التحميل ---
          if (provider.isLoading && provider.recommendations == null) {
            return const Center(child: RiveLoadingIndicator());
          }

          // --- الحالة 2: وجود خطأ ---
          if (provider.error != null) {
            return EmptyStateWidget(
              icon: Icons.signal_wifi_off_rounded,
              title: 'خطأ في جلب التوصيات',
              message: 'تأكد من اتصالك بالإنترنت ثم حاول مرة أخرى.',
              onRefresh: () => provider.fetchRecommendations(context),
            );
          }

          // --- الحالة 3: لا توجد بيانات (فارغة) ---
          if (provider.recommendations == null ||
              (provider.recommendations!.jobOpportunities!.isEmpty &&
                  provider.recommendations!.trainingCourses.isEmpty)) {
            return EmptyStateWidget(
              icon: Icons.auto_awesome,
              title: 'لا توجد توصيات لك بعد',
              message: 'للحصول على توصيات دقيقة، تأكد من إضافة وتحديث مهاراتك في ملفك الشخصي.',
              onRefresh: () => provider.fetchRecommendations(context),
            );
          }

          // --- الحالة 4: النجاح ووجود بيانات ---
          // هذا هو الجزء الذي كان يسبب المشكلة وتم تصحيحه
          final recommendations = provider.recommendations!;
          return RefreshIndicator(
            onRefresh: () => provider.fetchRecommendations(context),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- قسم توصيات الوظائف ---
                if (recommendations.jobOpportunities!.isNotEmpty) ...[
                  _buildSectionHeader(context, 'وظائف مقترحة', Icons.work),
                  ...recommendations.jobOpportunities!
                      .map((job) => _buildJobRecommendationCard(job))
                      .toList(),
                ],

                const SizedBox(height: 24),

                // --- قسم توصيات الدورات ---
                if (recommendations.trainingCourses!.isNotEmpty) ...[
                  _buildSectionHeader(context, 'دورات مقترحة', Icons.school),
                  ...recommendations.trainingCourses!
                      .map((course) => _buildCourseRecommendationCard(course))
                      .toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- دوال مساعدة لبناء الواجهة ---

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRecommendationCard(JobOpportunity job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.work_outline)),
        title: Text(job.jobTitle ?? 'وظيفة غير محددة', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(job.user?.firstName ?? 'شركة غير معروفة'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailScreen(job: job),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseRecommendationCard(TrainingCourse course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
        title: Text(course.courseName ?? 'دورة غير محددة', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('المدرب: ${course.trainersName ?? 'غير معروف'}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
      ),
    );
  }
}