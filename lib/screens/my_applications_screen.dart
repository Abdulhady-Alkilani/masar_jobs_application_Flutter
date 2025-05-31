import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_applications_provider.dart';
import '../models/job_application.dart';
// استيراد شاشات أخرى إذا كنت ستعرض تفاصيل الطلب أو الوظيفة من هنا
import 'job_opportunity_detail_screen.dart'; // لعرض تفاصيل الوظيفة المرتبطة

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({Key? key}) : super(key: key);

  @override
  _MyApplicationsScreenState createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    // جلب طلبات التوظيف الخاصة بالمستخدم عند الدخول للشاشة
    Provider.of<MyApplicationsProvider>(context, listen: false).fetchMyApplications(context);
  }

  // تابع لحذف طلب
  Future<void> _deleteApplication(int applicationId) async {
    final applicationsProvider = Provider.of<MyApplicationsProvider>(context, listen: false);
    try {
      await applicationsProvider.deleteApplication(context, applicationId);
      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الطلب بنجاح.')),
      );
    } catch (e) {
      // عرض رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إلغاء الطلب: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationsProvider = Provider.of<MyApplicationsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التوظيف الخاصة بي'),
      ),
      body: applicationsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : applicationsProvider.error != null
          ? Center(child: Text('Error: ${applicationsProvider.error}'))
          : applicationsProvider.applications.isEmpty
          ? const Center(child: Text('لم تقدم على أي فرص بعد.'))
          : ListView.builder(
        itemCount: applicationsProvider.applications.length,
        itemBuilder: (context, index) {
          final application = applicationsProvider.applications[index];
          return ListTile(
            title: Text(application.jobOpportunity?.jobTitle ?? 'وظيفة غير معروفة'),
            subtitle: Text('الحالة: ${application.status ?? 'غير محدد'}'),
            trailing: IconButton( // زر حذف/إلغاء الطلب
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // TODO: إضافة تأكيد قبل الحذف (AlertDialog)
                _deleteApplication(application.id!);
              },
            ),
            onTap: () {
              // TODO: الانتقال إلى شاشة تفاصيل الطلب أو تفاصيل الوظيفة المرتبطة
              if (application.jobId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobOpportunityDetailScreen(jobId: application.jobId!),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}