// lib/screens/public_views/PublicJobOpportunitiesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../../models/job_opportunity.dart';
import '../widgets/empty_state_widget.dart'; // تأكد من استيراد هذه الويدجت

class PublicJobOpportunitiesScreen extends StatefulWidget {
  const PublicJobOpportunitiesScreen({super.key});
  @override
  State<PublicJobOpportunitiesScreen> createState() => _PublicJobOpportunitiesScreenState();
}

class _PublicJobOpportunitiesScreenState extends State<PublicJobOpportunitiesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
      if (p.jobs.isEmpty) p.fetchJobOpportunities();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<PublicJobOpportunityProvider>();

    if (provider.isLoading && provider.jobs.isEmpty) {
      return _buildShimmerLoading();
    }
    if (provider.error != null && provider.jobs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.wifi_off_rounded,
        title: 'أُوпс! حدث خطأ',
        message: 'تعذر تحميل البيانات. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
        onRefresh: () => provider.fetchJobOpportunities(),
      );
    }
    if (provider.jobs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'لا توجد فرص حالياً',
        message: 'يبدو أنه لا توجد وظائف متاحة في الوقت الحالي. تحقق مرة أخرى لاحقاً!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchJobOpportunities(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: provider.jobs.length,
        itemBuilder: (context, index) {
          final job = provider.jobs[index];
          // --- هنا الاستدعاء الصحيح ---
          return JobCard(job: job) // <-- نمرر بيانات الوظيفة إلى البطاقة
              .animate(delay: (120 * (index % 10)).ms)
              .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
              .slideX(begin: -0.2, duration: 800.ms, curve: Curves.easeOutCubic);
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
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 140,
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

// --- ويدجت البطاقة المخصصة للوظائف ---
class JobCard extends StatefulWidget {
  final JobOpportunity job; // <-- هذا البارامتر مطلوب
  const JobCard({Key? key, required this.job}) : super(key: key); // <-- تم تعريفه هنا
  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        transform: _isHovered ? (Matrix4.identity()..translate(0.0, -8.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? theme.primaryColor : Colors.grey.shade200,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? theme.primaryColor.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              // TODO: الانتقال لصفحة تفاصيل الوظيفة
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(widget.job.type == 'تدريب' ? Icons.model_training_outlined : Icons.work_outline, color: theme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.jobTitle ?? 'عنوان غير معروف',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.job.user?.firstName ?? 'شركة غير معروفة',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}