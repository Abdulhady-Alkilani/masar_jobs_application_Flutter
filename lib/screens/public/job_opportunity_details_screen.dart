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
import '../../widgets/rive_loading_indicator.dart';

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
    // جلب البيانات مرة واحدة فقط ��ند تهيئة الشاشة
    _jobFuture = Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunityDetails(widget.jobId);
  }

  // دالة التقديم على الوظيفة
  void _applyForJob(JobOpportunity job) async {
    final myApplicationsProvider = Provider.of<MyApplicationsProvider>(context, listen: false);

    try {
      await myApplicationsProvider.applyForJob(context, job.jobId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تقديم طلبك بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
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
      backgroundColor: const Color(0xFFE0F7FA), // Very light sky blue
      body: FutureBuilder<JobOpportunity?>(
        future: _jobFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'خطأ',
              message: 'تعذر تحميل تفاصيل الفرصة. يرجى المحاولة مرة أخرى.',
              onRefresh: () {
                setState(() {
                  _jobFuture = Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunityDetails(widget.jobId);
                });
              },
            );
          }

          final job = snapshot.data!;
          final bool isExpired = job.endDate != null && job.endDate!.isBefore(DateTime.now());

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
                    job.jobTitle ?? 'تفاصيل الفرصة',
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
                    child: Icon(job.type == 'تدريب' ? Icons.model_training_outlined : Icons.work_outline, color: theme.primaryColor.withOpacity(0.2), size: 150),
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
                        _buildInfoCard(theme, job).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        _buildSection(theme, 'المؤهلات المطلوبة', job.qualification).animate().fadeIn(delay: 300.ms),
                        _buildSkillsSection(theme, 'المهارات المطلوبة', job.skills).animate().fadeIn(delay: 400.ms),
                        _buildSection(theme, 'الوصف التفصيلي', job.jobDescription, isDescription: true).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 40),
                        if (authProvider.isAuthenticated)
                          Center(
                            child: ElevatedButton.icon(
                              icon: Icon(isExpired ? Icons.lock_clock_outlined : Icons.send_rounded),
                              label: Text(isExpired ? 'الوظيفة منتهية' : 'تقديم طلب'),
                              onPressed: isExpired ? null : () => _applyForJob(job),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                disabledBackgroundColor: Colors.grey.shade400,
                                disabledForegroundColor: Colors.white,
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, JobOpportunity job) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow(theme, Icons.business_center_outlined, 'الناشر', job.user?.firstName ?? 'غير معروف'),
            _buildInfoRow(theme, Icons.calendar_today_outlined, 'تاريخ النشر', job.date != null ? DateFormat('d MMMM yyyy', 'ar').format(job.date!) : 'N/A'),
            _buildInfoRow(theme, Icons.event_busy_outlined, 'آخر موعد', job.endDate != null ? DateFormat('d MMMM yyyy', 'ar').format(job.endDate!) : 'N/A'),
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
    if (skillList.isEmpty) {
      return _buildSection(theme, title, 'لم يتم تحديد مهارات.');
    }
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