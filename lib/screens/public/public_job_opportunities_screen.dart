import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../widgets/rive_refresh_indicator.dart';
import '../../models/job_opportunity.dart';
import '../widgets/empty_state_widget.dart';
import 'job_opportunity_details_screen.dart';
import '../../widgets/rive_loading_indicator.dart';

class PublicJobOpportunitiesScreen extends StatefulWidget {
  final bool isGuest;
  const PublicJobOpportunitiesScreen({super.key, this.isGuest = false});
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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Builder(
        builder: (context) {
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.jobs.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.jobs.length) {
                  return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: RiveLoadingIndicator()));
                }
                final job = provider.jobs[index];
                return JobCard(job: job)
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

class JobCard extends StatelessWidget {
  final JobOpportunity job;
  const JobCard({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTraining = job.type == 'تدريب';
    final iconData = isTraining ? Icons.model_training_outlined : Icons.work_outline;

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
          if (job.jobId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicJobOpportunityDetailsScreen(jobId: job.jobId!),
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
                          job.user?.firstName ?? 'شركة غير معروفة',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (job.date != null)
                          Text(
                            DateFormat.yMMMd('ar').add_jm().format(job.date!),
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
                job.jobTitle ?? 'عنوان غير معروف',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (job.jobDescription != null && job.jobDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  job.jobDescription!,
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
                    label: Text(job.site ?? 'غير محدد'),
                    backgroundColor: theme.primaryColor.withOpacity(0.05),
                  ),
                  if (job.endDate != null)
                    Chip(
                      avatar: Icon(Icons.event_busy_outlined, size: 16, color: Colors.red.shade700),
                      label: Text('ينتهي في: ${DateFormat('dd/MM/yyyy', 'ar').format(job.endDate!)}'),
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
                      if (job.jobId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PublicJobOpportunityDetailsScreen(jobId: job.jobId!),
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