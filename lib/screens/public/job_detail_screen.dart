// lib/screens/public/job_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/job_opportunity.dart';
import '../../services/api_service.dart'; // For baseUrlStorage

class JobDetailScreen extends StatelessWidget {
  final JobOpportunity job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job.jobTitle ?? 'تفاصيل الوظيفة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.jobTitle ?? 'عنوان الوظيفة غير متوفر',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'الشركة: ${job.user?.firstName ?? 'غير معروف'} ${job.user?.lastName ?? ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, Icons.description, 'ا��وصف', job.jobDescription),
            _buildDetailRow(context, Icons.school, 'المؤهلات', job.qualification),
            _buildDetailRow(context, Icons.location_on, 'الموقع', job.site),
            _buildDetailRow(context, Icons.calendar_today, 'تاريخ النشر', job.date?.toLocal().toIso8601String().split('T')[0]),
            _buildDetailRow(context, Icons.calendar_month, 'تاريخ الانتهاء', job.endDate?.toLocal().toIso8601String().split('T')[0]),
            _buildDetailRow(context, Icons.category, 'النوع', job.type),
            _buildDetailRow(context, Icons.check_circle, 'الحالة', job.status),
            _buildDetailRow(context, Icons.lightbulb, 'المهارات المطلوبة', job.skills),
            // Add more details as needed
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
