import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_job_provider.dart'; // نستخدم نفس Provider للوظائف لكن نحتاج تابعاً جديداً للجلب
import '../models/job_opportunity.dart'; // تأكد من المسار
import 'admin_job_detail_screen.dart';
import 'edit_job_screen.dart'; // تأكد من المسار
// يمكنك استيراد شاشة إضافة وظيفة جديدة هنا إذا كان الأدمن يضيف وظيفة لشركة محددة مباشرة


class AdminManagedJobsByCompanyScreen extends StatefulWidget {
  final int companyId; // معرف الشركة

  const AdminManagedJobsByCompanyScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  _AdminManagedJobsByCompanyScreenState createState() => _AdminManagedJobsByCompanyScreenState();
}

class _AdminManagedJobsByCompanyScreenState extends State<AdminManagedJobsByCompanyScreen> {
  final ScrollController _scrollController = ScrollController();
  // يمكن إضافة حالة تحميل وخطأ وقائمة وظائف خاصة بهذه الشاشة هنا،
  // أو الأفضل: تعديل AdminJobProvider لدعم فلترة بالجلب

  @override
  void initState() {
    super.initState();
    // TODO: إضافة تابع fetchJobsByCompany(BuildContext context, int companyId, {int page}) إلى AdminJobProvider و ApiService
    // ثم استدعائه هنا بدلاً من fetchAllJobs
     Provider.of<AdminJobProvider>(context, listen: false).fetchJobsByCompany(context, widget.companyId);
    print('Admin Managed Jobs By Company Screen for Company ID: ${widget.companyId}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('وظيفة جلب وظائف شركة محددة لم تنفذ في Provider/ApiService.')),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // TODO: تابع لحذف فرصة عمل (سيستخدم AdminJobProvider.deleteJob)

  @override
  Widget build(BuildContext context) {
    // TODO: الاستماع لـ AdminJobProvider (ربما مع تابع جديد يجلب الوظائف بفلتر الشركة)
     final jobProvider = Provider.of<AdminJobProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('وظائف الشركة ID: ${widget.companyId}'), // يمكن عرض اسم الشركة هنا أيضاً
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة وظيفة جديدة (CreateEditJobScreen) مع تمرير معرف الشركة كقيمة افتراضية للناشر (UserID)
              print('Add Job Tapped for Company ID ${widget.companyId}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة وظيفة لشركة لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body:// const Center(child: Text('قائمة وظائف الشركة هنا...')), // Placeholder

       // TODO: بناء القائمة هنا باستخدام البيانات من Provider
       jobProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : jobProvider.error != null
                ? Center(child: Text('Error: ${jobProvider.error}'))
                : jobProvider.jobs.isEmpty // إذا كانت القائمة في Provider فارغة (بعد الفلترة)
                    ? const Center(child: Text('لا يوجد وظائف لهذه الشركة.'))
                    : ListView.builder(
                        controller: _scrollController,
                         itemCount: jobProvider.jobs.length + (jobProvider.isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                           if (index == jobProvider.jobs.length) {
                             return const Center(child: CircularProgressIndicator());
                           }
                          final job = jobProvider.jobs[index]; // هذه الوظيفة يجب أن تكون تابعة للشركة ID
                          return ListTile(
                            title: Text(job.jobTitle ?? 'بدون عنوان'),
                             subtitle: Text('الناشر UserID: ${job.userId ?? 'غير محدد'} - الحالة: ${job.status ?? ''}'),
                            trailing: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'تعديل',
                                    onPressed: () {
                                       if (job.jobId != null) {
                                         // الانتقال لتعديل الوظيفة
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditJobScreen(job: job),
                                            ),
                                          );
                                       }
                                    },
                                  ),
                                   IconButton(
                                     icon: const Icon(Icons.delete, color: Colors.red),
                                     tooltip: 'حذف',
                                     onPressed: () {
                                        if (job.jobId != null) {
                                          // TODO: تابع لحذف الوظيفة (adminJobProvider.deleteJob) مع تأكيد
                                        }
                                     },
                                   ),
                                ],
                             ),
                            onTap: () {
                              // الانتقال لتفاصيل فرصة العمل
                               if (job.jobId != null) {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => AdminJobDetailScreen(jobId: job.jobId!),
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

// TODO: يجب إضافة تابع fetchJobsByCompany(BuildContext context, int companyId, {int page})
// إلى AdminJobProvider و ApiService لدعم جلب الوظائف لشركة محددة.