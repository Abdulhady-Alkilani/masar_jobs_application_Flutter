// lib/screens/public_views/PublicJobOpportunitiesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../../models/job_opportunity.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/rive_refresh_indicator.dart';
import 'job_opportunity_details_screen.dart';


class PublicJobOpportunitiesScreen extends StatefulWidget {
  const PublicJobOpportunitiesScreen({super.key});
  @override
  State<PublicJobOpportunitiesScreen> createState() => _PublicJobOpportunitiesScreenState();
}

class _PublicJobOpportunitiesScreenState extends State<PublicJobOpportunitiesScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
      if (p.jobs.isEmpty) {
        p.fetchJobOpportunities();
      }
    });

    _scrollController.addListener(() {
      final provider = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreJobOpportunities();
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
    final provider = context.watch<PublicJobOpportunityProvider>();

    if (provider.isLoading && provider.jobs.isEmpty) return _buildShimmerLoading();
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

    return RiveRefreshIndicator(
      onRefresh: () => provider.fetchJobOpportunities(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.jobs.length + (provider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.jobs.length) {
            return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
          }
          final job = provider.jobs[index];
          return JobCard(job: job)
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
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 140,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class JobCard extends StatefulWidget {
  final JobOpportunity job;
  const JobCard({Key? key, required this.job}) : super(key: key);
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
        transform: _isHovered ? (Matrix4.identity()..scale(1.03)..translate(0.0, -5.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? theme.primaryColor.withOpacity(0.25) : Colors.black.withOpacity(0.07),
              blurRadius: _isHovered ? 25 : 10,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.job.jobId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicJobOpportunityDetailsScreen(jobId: widget.job.jobId!),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(widget.job.type == 'تدريب' ? Icons.model_training_outlined : Icons.work_outline, color: theme.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.job.jobTitle ?? 'عنوان غير معروف', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.job.user?.firstName ?? 'شركة غير معروفة', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(widget.job.site ?? 'غير محدد', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                          ],
                        ),
                        if (widget.job.endDate != null)
                          Text(
                            'ينتهي في: ${DateFormat('dd/MM/yyyy', 'ar').format(widget.job.endDate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                          ),
                      ],
                    )
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