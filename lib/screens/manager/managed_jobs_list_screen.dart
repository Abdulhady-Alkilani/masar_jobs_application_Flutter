// lib/screens/manager/managed_jobs_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/managed_job_opportunity_provider.dart';
import '../../models/job_opportunity.dart';
import '../../services/api_service.dart';
import 'create_edit_job_screen.dart';
import 'job_applicants_screen.dart';
import '../../widgets/rive_loading_indicator.dart';

class ManagedJobsListScreen extends StatefulWidget {
  const ManagedJobsListScreen({super.key});

  @override
  State<ManagedJobsListScreen> createState() => _ManagedJobsListScreenState();
}

class _ManagedJobsListScreenState extends State<ManagedJobsListScreen> {
  @override
  void initState() {
    super.initState();
    // جلب الوظائف عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManagedJobOpportunityProvider>(context, listen: false).fetchManagedJobs(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ManagedJobOpportunityProvider>(
        builder: (context, jobProvider, child) {
          if (jobProvider.isLoading) {
            return const Center(child: RiveLoadingIndicator());
          }

          if (jobProvider.error != null) {
            return Center(child: Text('خطأ: ${jobProvider.error}'));
          }

          if (jobProvider.managedJobs.isEmpty) {
            return const Center(
              child: Text(
                'لم تقم بإضافة أي فرص عمل بعد.\nاضغط على زر + للبدء.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => jobProvider.fetchManagedJobs(context),
            child: ListView.builder(
              itemCount: jobProvider.managedJobs.length,
              itemBuilder: (context, index) {
                final job = jobProvider.managedJobs[index];
                return _buildJobCard(context, job, jobProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // الانتقال لشاشة إنشاء وظيفة جديدة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditJobScreen(), // لا نمرر وظيفة عند الإنشاء
            ),
          );
        },
        tooltip: 'إضافة فرصة عمل جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobOpportunity job, ManagedJobOpportunityProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // عرض المتقدمين لهذه الوظيفة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobApplicantsScreen(jobId: job.jobId!, jobTitle: job.jobTitle ?? ''),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.jobTitle ?? 'بدون عنوان',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEditJobScreen(job: job),
                          ),
                        );
                      } else if (value == 'delete') {
                        // طلب تأكيد الحذف
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('تأكيد الحذف'),
                            content: Text('هل أنت متأكد من رغبتك في حذف "${job.jobTitle}"؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ?? false;

                        if (confirm) {
                          try {
                            await provider.deleteJob(context, job.jobId!);
                          } on ApiException catch(e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: ${e.message}')));
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(job.site ?? 'غير محدد', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  // TODO: عرض عدد المتقدمين إذا كان متاحاً في الموديل
                  const Text(' 6 متقدمين'), // مثال
                  const Spacer(),
                  Chip(
                    label: Text(job.status ?? 'حالة غير معروفة'),
                    padding: EdgeInsets.zero,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}