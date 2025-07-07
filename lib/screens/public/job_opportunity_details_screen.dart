// lib/screens/public_views/public_job_opportunity_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/job_opportunity.dart';
import '../../providers/my_applications_provider.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/empty_state_widget.dart';

class PublicJobOpportunityDetailsScreen extends StatefulWidget {
  final int jobId;
  const PublicJobOpportunityDetailsScreen({super.key, required this.jobId});

  @override
  State<PublicJobOpportunityDetailsScreen> createState() => _PublicJobOpportunityDetailsScreenState();
}

class _PublicJobOpportunityDetailsScreenState extends State<PublicJobOpportunityDetailsScreen> {
  late Future<JobOpportunity?> _jobFuture;

  @override
  void initState() {
    super.initState();
    // جلب البيانات مرة واحدة فقط عند تهيئة الشاشة
    _jobFuture = Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunity(widget.jobId);
  }

  // دالة التقديم على الوظيفة
  void _applyForJob(JobOpportunity job) async {
    final myApplicationsProvider = Provider.of<MyApplicationsProvider>(context, listen: false);

    // يمكنك هنا عرض نموذج لإدخال رسالة تعريفية أو تحميل سيرة ذاتية
    // حالياً، سنقوم بالتقديم مباشرة
    try {
      await myApplicationsProvider.applyForJob(context, job.jobId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تقديم طلبك بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      // يمكنك إعادة توجيه المستخدم أو تحديث الحالة هنا
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التقديم: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<JobOpportunity?>(
        future: _jobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'خطأ',
              message: 'تعذر تحميل تفاصيل الفرصة. يرجى المحاولة مرة أخرى.',
              onRefresh: () {
                setState(() {
                  _jobFuture = Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunity(widget.jobId);
                });
              },
            );
          }

          final job = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // 1. الشريط العلوي (Header)
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                stretch: true,
                backgroundColor: theme.primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  title: Text(
                    job.jobTitle ?? 'تفاصيل الفرصة',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, theme.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(job.type == 'تدريب' ? Icons.model_training_outlined : Icons.work_outline, color: Colors.white24, size: 120),
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
                        _buildInfoCard(theme, job).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        _buildSection(theme, 'المؤهلات المطلوبة', job.qualification).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                        _buildSkillsSection(theme, 'المهارات المطلوبة', job.skills).animate().fadeIn(delay: 400.ms),
                        _buildSection(theme, 'الوصف التفصيلي', job.jobDescription, isDescription: true).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 40),
                        if (authProvider.isAuthenticated)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('تقديم طلب'),
                              onPressed: () => _applyForJob(job),
                              style: theme.elevatedButtonTheme.style?.copyWith(
                                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                              ),
                            ).animate(delay: 600.ms).scale(duration: 500.ms, curve: Curves.elasticOut),
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
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
    );
  }

  Widget _buildInfoCard(ThemeData theme, JobOpportunity job) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(theme, Icons.business_center_outlined, 'الناشر', job.user?.firstName ?? 'غير معروف'),
            _buildInfoRow(theme, Icons.calendar_today_outlined, 'تاريخ النشر', job.date != null ? DateFormat('dd/MM/yyyy', 'ar').format(job.date!) : 'N/A'),
            _buildInfoRow(theme, Icons.event_busy_outlined, 'آخر موعد', job.endDate != null ? DateFormat('dd/MM/yyyy', 'ar').format(job.endDate!) : 'N/A'),
            _buildInfoRow(theme, Icons.location_on_outlined, 'الموقع', job.site ?? 'غير محدد', noDivider: true),
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
            style: theme.textTheme.bodyLarge?.copyWith(height: isDescription ? 1.7 : 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(ThemeData theme, String title, String? skills) {
    final skillList = skills?.split(',').where((s) => s.trim().isNotEmpty).toList() ?? [];
    if (skillList.isEmpty) {
      return _buildSection(theme, title, 'لم يتم تحديد مهارات.');
    }
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