import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_job_provider.dart'; // نستخدم نفس Provider للوظائف لكن نحتاج تابعاً جديداً للجلب
import '../models/job_opportunity.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO المطلوبة
import 'admin_job_detail_screen.dart';
import 'create_edit_job_screen.dart'; // <--- شاشة إضافة/تعديل فرصة عمل


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
    Provider.of<AdminJobProvider>(context, listen: false).fetchJobsByCompany(context, widget.companyId); // استدعاء تابع الجلب
    print('Admin Managed Jobs By Company Screen for Company ID: ${widget.companyId}');
    // لا حاجة لـ SnackBar هنا، Provider هو من يعرض الخطأ أو حالة التحميل
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وظيفة جلب وظائف شركة محددة لم تنفذ في Provider/ApiService.')));


    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق من أن هناك المزيد لتحميله ومن أننا لسنا بصدد جلب بالفعل
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !Provider.of<AdminJobProvider>(context, listen: false).isFetchingMore &&
          Provider.of<AdminJobProvider>(context, listen: false).hasMorePages) {
        // TODO: إضافة تابع fetchMoreJobsByCompany إلى AdminJobProvider
        // Provider.of<AdminJobProvider>(context, listen: false).fetchMoreJobsByCompany(context, widget.companyId);
        print('Fetch more jobs for company ID: ${widget.companyId} tapped.');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // تابع لحذف فرصة عمل
  Future<void> _deleteJob(int jobId) async {
    // يمكن إضافة حالة تحميل خاصة هنا إذا أردت (في Stateful Widget)
    // setState(() { _isDeleting = true; }); // مثال


    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف فرصة العمل هذه؟'), // يمكنك عرض المسمى الوظيفي هنا
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );


    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه
      final provider = Provider.of<AdminJobProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteJob(context, jobId);
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف فرصة العمل بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف فرصة العمل: ${e.toString()}')),
        );
      } finally {
        // setState(() { _isDeleting = false; }); // مثال
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final jobProvider = Provider.of<AdminJobProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('وظائف الشركة ID: ${widget.companyId}'), // يمكن عرض اسم الشركة هنا أيضاً
        actions: [
          // زر إضافة فرصة عمل جديدة
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: jobProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
              // الانتقال إلى شاشة إضافة فرصة عمل جديدة (CreateEditJobScreen)
              print('Add Job Tapped for Company ID ${widget.companyId}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  // نمرر null لـ job للإشارة إلى أنها شاشة إضافة
                  // TODO: إذا كان الأدمن ينشئ وظيفة لشركة محددة، قد تحتاج لتمرير معرف الشركة كقيمة افتراضية لحقل UserID في شاشة الإضافة/التعديل
                  builder: (context) => const CreateEditJobScreen(job: null),
                ),
              );
            },
          ),
        ],
      ),
      body: jobProvider.isLoading && jobProvider.jobs.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : jobProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${jobProvider.error}'))
          : jobProvider.jobs.isEmpty // إذا كانت القائمة في Provider فارغة (بعد الفلترة)
          ? const Center(child: Text('لا يوجد وظائف لهذه الشركة.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: jobProvider.jobs.length + (jobProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == jobProvider.jobs.length) {
            // إذا كنا في حالة جلب المزيد، اعرض مؤشر
            return jobProvider.isFetchingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(); // وإلا لا تعرض شيئاً
          }

          final job = jobProvider.jobs[index]; // هذه الوظيفة يجب أن تكون تابعة للشركة ID
          // تأكد أن الوظيفة لديها ID قبل عرض أزرار التعديل/الحذف أو الانتقال
          if (job.jobId == null) return const SizedBox.shrink();


          return ListTile(
            title: Text(job.jobTitle ?? 'بدون عنوان'),
            subtitle: Text('الناشر UserID: ${job.userId ?? 'غير محدد'} - الحالة: ${job.status ?? ''}'), // عرض الحالة هنا
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر تعديل فرصة عمل
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: jobProvider.isLoading ? null : () { // تعطيل الزر أثناء تحميل أي عملية في Provider
                    // الانتقال إلى شاشة تعديل فرصة عمل
                    print('Edit Job Tapped for ID ${job.jobId}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // نمرر كائن الوظيفة لـ CreateEditJobScreen للإشارة إلى أنها شاشة تعديل
                        builder: (context) => CreateEditJobScreen(job: job),
                      ),
                    );
                  },
                ),
                // زر حذف فرصة عمل
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: jobProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                    _deleteJob(job.jobId!); // استدعاء تابع الحذف
                  },
                ),
              ],
            ),
            // onTap لعرض تفاصيل فرصة العمل
            onTap: jobProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
              // الانتقال لتفاصيل فرصة العمل
              print('Job Tapped: ${job.jobId}');
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