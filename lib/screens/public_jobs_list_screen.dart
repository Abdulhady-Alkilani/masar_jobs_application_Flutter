import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_job_opportunity_provider.dart';
import '../models/job_opportunity.dart';
import 'job_opportunity_detail_screen.dart'; // تأكد من المسار

class PublicJobsListScreen extends StatefulWidget {
  const PublicJobsListScreen({Key? key}) : super(key: key);

  @override
  _PublicJobsListScreenState createState() => _PublicJobsListScreenState();
}

class _PublicJobsListScreenState extends State<PublicJobsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunities();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchMoreJobOpportunities();
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
    final jobProvider = Provider.of<PublicJobOpportunityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فرص العمل والتدريب'),
      ),
      body: jobProvider.isLoading && jobProvider.jobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : jobProvider.error != null
          ? Center(child: Text('Error: ${jobProvider.error}'))
          : jobProvider.jobs.isEmpty
          ? const Center(child: Text('لا توجد فرص متاحة حالياً.'))
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
            subtitle: Text('${job.type ?? ''} - ${job.site ?? ''}'),
            trailing: Text(job.date?.toString().split(' ')[0] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobOpportunityDetailScreen(jobId: job.jobId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}