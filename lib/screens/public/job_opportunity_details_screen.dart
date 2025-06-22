// lib/screens/public/job_opportunity_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../../providers/my_applications_provider.dart'; // لتقديم طلب
import '../../providers/auth_provider.dart'; // للتحقق من المصادقة
import '../../models/job_opportunity.dart';

class JobOpportunityDetailsScreen extends StatelessWidget {
  final int jobId;

  const JobOpportunityDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفرصة'),
      ),
      body: FutureBuilder<JobOpportunity?>(
        future: Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunity(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('ไม่สามารถ تحميل التفاصيل'));
          }

          final job = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.jobTitle ?? '', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('بواسطة: ${job.user?.firstName ?? ''}', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                const SizedBox(height: 8),
                Text('الموقع: ${job.site ?? ''}', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                const Divider(height: 32),

                _buildSectionTitle('الوصف الوظيفي'),
                Text(job.jobDescription ?? 'لا يوجد وصف.'),
                const SizedBox(height: 24),

                _buildSectionTitle('المؤهلات المطلوبة'),
                Text(job.qualification ?? 'لم تحدد المؤهلات.'),
                const SizedBox(height: 24),

                _buildSectionTitle('المهارات'),
                // عرض المهارات كـ Chips
                if (job.skills != null && job.skills!.isNotEmpty)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: job.skills!.split(',').map((skill) => Chip(label: Text(skill.trim()))).toList(),
                  )
                else
                  const Text('لم تحدد المهارات.'),
              ],
            ),
          );
        },
      ),
      // زر التقديم يظهر فقط للمستخدمين المسجلين (الخريجين)
      floatingActionButton: authProvider.isAuthenticated && authProvider.user?.type == 'خريج'
          ? FloatingActionButton.extended(
        onPressed: () {
          // TODO: فتح شاشة أو مربع حوار للتقديم على الوظيفة
          // يمكن من خلاله كتابة رسالة تغطية ورفع سيرة ذاتية
          _showApplyDialog(context, jobId);
        },
        label: const Text('التقديم الآن'),
        icon: const Icon(Icons.send),
      )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // مربع حوار للتقديم على الوظيفة
  void _showApplyDialog(BuildContext context, int jobId) {
    final applicationsProvider = Provider.of<MyApplicationsProvider>(context, listen: false);
    // يمكنك إضافة Controllers هنا لرسالة التغطية

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('التقديم على الوظيفة'),
          content: const Text('هل أنت متأكد من رغبتك في إرسال طلبك لهذه الوظيفة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await applicationsProvider.applyForJob(context, jobId);
                  Navigator.pop(context); // أغلق الحوار
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح'), backgroundColor: Colors.green));
                } catch (e) {
                  Navigator.pop(context); // أغلق الحوار
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التقديم: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('تأكيد التقديم'),
            ),
          ],
        );
      },
    );
  }
}