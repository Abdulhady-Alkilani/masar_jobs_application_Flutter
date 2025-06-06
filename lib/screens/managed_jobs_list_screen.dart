import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_job_opportunity_provider.dart';
import '../models/job_opportunity.dart';
import 'create_job_screen.dart';
import 'managed_job_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة وظيفة جديدة

class ManagedJobsListScreen extends StatefulWidget {
  const ManagedJobsListScreen({Key? key}) : super(key: key);

  @override
  _ManagedJobsListScreenState createState() => _ManagedJobsListScreenState();
}

class _ManagedJobsListScreenState extends State<ManagedJobsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<ManagedJobOpportunityProvider>(context, listen: false).fetchManagedJobs(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<ManagedJobOpportunityProvider>(context, listen: false).fetchMoreManagedJobs(context);
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
    final jobProvider = Provider.of<ManagedJobOpportunityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فرص عملي المنشورة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة وظيفة جديدة (CreateJobScreen)
              print('Add Job Tapped');
               Navigator.push(context, MaterialPageRoute(builder: (context) => CreateJobScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة وظيفة لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: jobProvider.isLoading && jobProvider.managedJobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : jobProvider.error != null
          ? Center(child: Text('Error: ${jobProvider.error}'))
          : jobProvider.managedJobs.isEmpty
          ? const Center(child: Text('لم تنشر أي فرص عمل بعد.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: jobProvider.managedJobs.length + (jobProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == jobProvider.managedJobs.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final job = jobProvider.managedJobs[index];
          return ListTile(
            title: Text(job.jobTitle ?? 'بدون عنوان'),
            subtitle: Text('${job.type ?? ''} - ${job.site ?? ''} (${job.status ?? ''})'), // عرض الحالة هنا
            trailing: Text(job.date?.toString().split(' ')[0] ?? ''),
            onTap: () {
              // الانتقال لتفاصيل الوظيفة (للمدير)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagedJobDetailScreen(jobId: job.jobId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateJobScreen لإضافة وظيفة جديدة (ستحتاج ManagedJobOpportunityProvider.createJob)