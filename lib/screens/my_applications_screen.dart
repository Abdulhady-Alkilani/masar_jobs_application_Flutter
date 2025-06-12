import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_applications_provider.dart'; // لجلب وحذف الطلبات
import '../models/job_application.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات أخرى إذا كنت ستعرض تفاصيل الطلب أو الوظيفة من هنا
import 'job_opportunity_detail_screen.dart'; // لعرض تفاصيل الوظيفة المرتبطة
// TODO: يمكنك إضافة شاشة تفاصيل طلب توظيف إذا أردت عرض تفاصيل الطلب نفسه بشكل أوسع


class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({Key? key}) : super(key: key);

  @override
  _MyApplicationsScreenState createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  // لا نحتاج ScrollController هنا لأن MyApplicationsProvider لا يستخدم Pagination حالياً
  // إذا أضفت Pagination لاحقاً، ستحتاج إضافة ScrollController ومستمع له

  @override
  void initState() {
    super.initState();
    // جلب طلبات التوظيف الخاصة بالمستخدم عند الدخول للشاشة
    // fetchMyApplications يتطلب context
    Provider.of<MyApplicationsProvider>(context, listen: false).fetchMyApplications(context);
  }

  @override
  void dispose() {
    // إذا أضفت ScrollController، لا تنسى dispose هنا
    super.dispose();
  }

  // تابع لحذف طلب
  Future<void> _deleteApplication(JobApplication application) async { // تقبل كائن الطلب بالكامل
    // لا يمكن الحذف بدون معرف الطلب
    if (application.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرف الطلب غير متاح للحذف.')),
      );
      return;
    }

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>( // عرض مربع حوار تأكيد
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد إلغاء الطلب'),
          content: Text('هل أنت متأكد أنك تريد إلغاء الطلب على وظيفة "${application.jobOpportunity?.jobTitle ?? 'بدون عنوان'}"؟'), // عرض عنوان الوظيفة في الرسالة
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }), // إغلاق المربع وإرجاع false
            TextButton(child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }), // إغلاق المربع وإرجاع true
          ],
        );
      },
    );


    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه (MyApplicationsProvider.isLoading)
      final provider = Provider.of<MyApplicationsProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteApplication(context, application.id!); // استدعاء تابع الحذف مع معرف الطلب
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الطلب بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل إلغاء الطلب: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إلغاء الطلب: ${e.toString()}')),
        );
      } finally {
        // لا حاجة لتحديث حالة التحميل هنا، Provider سيتكفل بذلك
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
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
        // لا يوجد ScrollController هنا حالياً
        itemCount: applicationsProvider.applications.length,
        itemBuilder: (context, index) {
          final application = applicationsProvider.applications[index];
          // تأكد أن الطلب لديه ID قبل عرض زر الحذف
          if (application.id == null) return const SizedBox.shrink();


          return ListTile(
            title: Text(application.jobOpportunity?.jobTitle ?? 'وظيفة غير معروفة'),
            subtitle: Text('الحالة: ${application.status ?? 'غير محدد'}'),
            trailing: IconButton( // زر حذف/إلغاء الطلب
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: applicationsProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                _deleteApplication(application); // <--- استدعاء تابع الحذف مع تمرير كائن الطلب
              },
            ),
            onTap: applicationsProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
              // TODO: الانتقال إلى شاشة تفاصيل الطلب أو تفاصيل الوظيفة المرتبطة
              // يمكنك اختيار عرض تفاصيل الطلب نفسه أولاً، أو الانتقال مباشرة لتفاصيل الوظيفة
              print('Application Tapped: ${application.id}');
              // مثال الانتقال لتفاصيل الوظيفة المرتبطة بالطلب
              if (application.jobId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobOpportunityDetailScreen(jobId: application.jobId!), // <--- الانتقال لشاشة تفاصيل الوظيفة العامة
                  ),
                );
              } else {
                // إذا لم يكن هناك معرف وظيفة (حالة غير متوقعة)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('معرف الوظيفة المرتبطة غير متاح.')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// Simple extension for List<JobApplication> if needed
extension ListJobApplicationExtension on List<JobApplication> {
  JobApplication? firstWhereOrNull(bool Function(JobApplication) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}