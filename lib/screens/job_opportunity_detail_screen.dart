import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_job_opportunity_provider.dart';
import '../models/job_opportunity.dart';
import '../providers/my_applications_provider.dart'; // لجلب وتقديم طلبات المستخدم

class JobOpportunityDetailScreen extends StatelessWidget {
  final int jobId;

  const JobOpportunityDetailScreen({Key? key, required this.jobId}) : super(key: key);

  // TODO: أضف منطق لتقديم الطلب (Apply) هنا أو في صفحة منفصلة
  // يمكن استخدام RaisedButton/ElevatedButton لاستدعاء jobApplicationsProvider.applyForJob

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
    final applicationsProvider = Provider.of<MyApplicationsProvider>(context, listen: false); // للتقديم

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفرصة'),
      ),
      body: FutureBuilder<JobOpportunity?>(
        future: jobProvider.fetchJobOpportunity(jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final error = jobProvider.error ?? snapshot.error?.toString() ?? 'حدث خطأ غير متوقع';
            return Center(child: Text('Error: $error'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('الفرصة غير موجودة.'));
          } else {
            final job = snapshot.data!;
            // TODO: تحقق هنا إذا كان المستخدم قد قدم على هذه الوظيفة لعرض زر "تم التقديم" بدلاً من "تقديم طلب"
            // يمكنك جلب قائمة طلبات المستخدم من MyApplicationsProvider عند تحميل هذه الصفحة أو التحقق منها هنا

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.jobTitle ?? 'بدون عنوان',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'النوع: ${job.type ?? 'غير معروف'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'المكان: ${job.site ?? 'غير محدد'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'تاريخ النشر: ${job.date?.toString().split(' ')[0] ?? 'غير معروف'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (job.endDate != null)
                    Text(
                      'تاريخ الانتهاء: ${job.endDate!.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 14, color: Colors.redAccent),
                    ),
                  const SizedBox(height: 16),
                  const Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(job.jobDescription ?? 'لا يوجد وصف.', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  if (job.qualification != null && job.qualification!.isNotEmpty) ...[
                    const Text('المؤهلات المطلوبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(job.qualification!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                  ],
                  if (job.skills != null && job.skills!.isNotEmpty) ...[
                    const Text('المهارات المطلوبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(job.skills!, style: const TextStyle(fontSize: 16)), // يعرض المهارات كنص كما هي في DB
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'الناشر: ${job.user?.firstName ?? ''} ${job.user?.lastName ?? ''}',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  // TODO: زر تقديم الطلب
                  const SizedBox(height: 24),
                  // بناءً على حالة المستخدم (مصادق عليه وخريج) وحالة الوظيفة (مفعل ولم يتم التقديم عليها)
                  // يمكنك عرض زر التقديم أو رسالة "تم التقديم" أو رسالة "سجل دخول للتقديم"
                  ElevatedButton(
                    onPressed: () {
                      // TODO: تنفيذ منطق تقديم الطلب
                      print('Apply button tapped for job ID ${job.jobId}');
                      // مثال بسيط جداً لاستدعاء التابع (يحتاج تأكيد المستخدم والـ CV)
                      // applicationsProvider.applyForJob(context, job.jobId!, description: 'My notes', cvPath: '/path/to/cv.pdf');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('وظيفة زر التقديم لم تنفذ بالكامل بعد.')),
                      );
                    },
                    child: const Text('تقديم طلب'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}