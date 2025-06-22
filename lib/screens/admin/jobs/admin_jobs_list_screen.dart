// lib/screens/admin/jobs/admin_jobs_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_job_provider.dart';
import '../../../models/job_opportunity.dart';
import 'admin_create_edit_job_screen.dart'; // سننشئه لاحقًا
import '../../../services/api_service.dart';

class AdminJobsListScreen extends StatefulWidget {
  const AdminJobsListScreen({super.key});

  @override
  State<AdminJobsListScreen> createState() => _AdminJobsListScreenState();
}

class _AdminJobsListScreenState extends State<AdminJobsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AdminJobProvider>(context, listen: false);
    provider.fetchAllJobs(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreJobs(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteJob(JobOpportunity job, AdminJobProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف وظيفة "${job.jobTitle}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await provider.deleteJob(context, job.jobId!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الوظيفة بنجاح'), backgroundColor: Colors.green));
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوظائف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'إضافة وظيفة جديدة',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEditJobScreen()));
            },
          ),
        ],
      ),
      body: Consumer<AdminJobProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.jobs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.jobs.isEmpty) {
            return Center(child: Text('حدث خطأ: ${provider.error}'));
          }
          if (provider.jobs.isEmpty) {
            return const Center(child: Text('لا توجد وظائف حاليًا.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllJobs(context),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.jobs.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.jobs.length) {
                  return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                }
                final job = provider.jobs[index];
                return _buildJobCard(job, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(JobOpportunity job, AdminJobProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(job.type == 'وظيفة' ? Icons.work : Icons.model_training)),
        title: Text(job.jobTitle ?? 'عنوان غير معروف'),
        subtitle: Text('${job.site ?? 'موقع غير محدد'} - الناشر: ${job.user?.firstName ?? 'غير معروف'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCreateEditJobScreen(job: job)));
            } else if (value == 'delete') {
              _deleteJob(job, provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}