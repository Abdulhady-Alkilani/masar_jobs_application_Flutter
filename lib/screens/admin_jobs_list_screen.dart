import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_job_provider.dart'; // تأكد من المسار
import '../models/job_opportunity.dart'; // تأكد من المسار
import 'admin_job_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة/تعديل فرصة عمل


class AdminJobsListScreen extends StatefulWidget {
  const AdminJobsListScreen({Key? key}) : super(key: key);

  @override
  _AdminJobsListScreenState createState() => _AdminJobsListScreenState();
}

class _AdminJobsListScreenState extends State<AdminJobsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<AdminJobProvider>(context, listen: false).fetchAllJobs(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<AdminJobProvider>(context, listen: false).fetchMoreJobs(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // TODO: تابع لحذف فرصة عمل (adminJobProvider.deleteJob) مع تأكيد

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<AdminJobProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة فرص العمل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة فرصة عمل جديدة (CreateEditJobScreen)
              print('Add Job Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة فرصة عمل لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: jobProvider.isLoading && jobProvider.jobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : jobProvider.error != null
          ? Center(child: Text('Error: ${jobProvider.error}'))
          : jobProvider.jobs.isEmpty
          ? const Center(child: Text('لا توجد فرص عمل.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: jobProvider.jobs.length + (jobProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == jobProvider.jobs.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final job = jobProvider.jobs[index];
          return ListTile(
            title: Text(job.jobTitle ?? 'بدون عنوان'),
            subtitle: Text('الناشر UserID: ${job.userId ?? 'غير محدد'} - النوع: ${job.type ?? ''} - الحالة: ${job.status ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: () {
                    // TODO: الانتقال إلى شاشة تعديل فرصة عمل (CreateEditJobScreen) مع تمرير بيانات الفرصة
                    print('Edit Job Tapped for ID ${job.jobId}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة تعديل فرصة عمل لم تنفذ.')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: () {
                    if (job.jobId != null) {
                      // TODO: تابع لحذف فرصة العمل (adminJobProvider.deleteJob) مع تأكيد
                      print('Delete Job Tapped for ID ${job.jobId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('وظيفة حذف فرصة عمل لم تنفذ.')),
                      );
                    }
                  },
                ),
              ],
            ),
            onTap: () {
              // الانتقال لتفاصيل فرصة العمل
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminJobDetailScreen(jobId: job.jobId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateEditJobScreen لإضافة أو تعديل فرصة عمل (تحتاج AdminJobProvider.createJob و .updateJob)
// TODO: أنشئ شاشة AdminJobDetailScreen لعرض تفاصيل فرصة عمل (تحتاج AdminJobProvider.fetchJob أو استخدام public fetch)