import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_job_provider.dart'; // نحتاجها لتنفيذ التعديل/الحذف وربما جلب التفاصيل
// import '../providers/public_job_opportunity_provider.dart'; // قد نستخدمه لجلب التفاصيل
import '../models/job_opportunity.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات الـ TODO
import 'edit_job_screen.dart'; // شاشة التعديل
import 'admin_job_applicants_screen.dart'; // <--- تأكد من المسار (شاشة المتقدمين للأدمن)


class AdminJobDetailScreen extends StatefulWidget {
  final int jobId; // معرف فرصة العمل

  const AdminJobDetailScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _AdminJobDetailScreenState createState() => _AdminJobDetailScreenState();
}

class _AdminJobDetailScreenState extends State<AdminJobDetailScreen> {
  JobOpportunity? _job;
  String? _jobError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchJob(); // جلب تفاصيل فرصة العمل عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل فرصة العمل المحدد
  Future<void> _fetchJob() async {
    setState(() { _isLoading = true; _jobError = null; });

    // هنا يجب استخدام تابع يجلب تفاصيل وظيفة واحدة للأدمن
    // إذا كان هناك تابع fetchSingleJob في AdminJobProvider، استخدمه.
    // إذا لم يكن، يمكنك استدعاء ApiService مباشرةً أو إضافة التابع لـ AdminJobProvider.
    // بناءً على api.php، المسار هو GET /admin/jobs/{job_id}، لذا يفترض وجود تابع في ApiService و AdminJobProvider.

    final adminJobProvider = Provider.of<AdminJobProvider>(context, listen: false);
    // TODO: إضافة تابع fetchSingleJob(BuildContext context, int jobId) إلى AdminJobProvider و ApiService
    // For now, simulate fetching from the list or show error if not found
    JobOpportunity? fetchedJob = ListJobExtension(adminJobProvider.jobs).firstWhereOrNull((j) => j.jobId == widget.jobId);

    if (fetchedJob != null) {
      setState(() {
        _job = fetchedJob;
        _jobError = null;
      });
    } else {
      // Fallback: حاول جلب القائمة مرة أخرى كحل مؤقت غير فعال للقوائم الكبيرة
      await adminJobProvider.fetchAllJobs(context);
      fetchedJob = ListJobExtension(adminJobProvider.jobs).firstWhereOrNull((j) => j.jobId == widget.jobId);

      if (fetchedJob != null) {
        setState(() { _job = fetchedJob; _jobError = null; });
      } else {
        // إذا لم يُعثر عليه بعد المحاولة، اعرض خطأ
        setState(() { _job = null; _jobError = 'الوظيفة بمعرف ${widget.jobId} غير موجودة أو فشل جلبها.'; });
      }
      // TODO: الأفضل هو استخدام تابع fetchSingleJob من AdminJobProvider
    }


    setState(() { _isLoading = false; }); // انتهاء التحميل بعد المحاولة
  }

  // تابع لحذف فرصة العمل
  Future<void> _deleteJob() async {
    if (_job?.jobId == null) return; // لا يمكن الحذف بدون معرف

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف
    final confirmed = await showDialog<bool>( // عرض مربع حوار تأكيد
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف فرصة العمل "${_job!.jobTitle ?? 'بدون عنوان'}"؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () { Navigator.of(dialogContext).pop(false); },
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
              onPressed: () { Navigator.of(dialogContext).pop(true); },
            ),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      setState(() { _isLoading = true; _jobError = null; }); // بداية التحميل

      final provider = Provider.of<AdminJobProvider>(context, listen: false);
      try {
        await provider.deleteJob(context, _job!.jobId!); // استدعاء تابع الحذف
        // بعد النجاح، العودة إلى شاشة قائمة الوظائف المنشورة
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف فرصة العمل بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف فرصة العمل: ${e.toString()}')),
        );
      } finally {
        setState(() { _isLoading = false; }); // انتهاء التحميل
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع لـ provider هنا إلا إذا كان له حالة تحميل خاصة بعمليات التعديل/الحذف
    // final adminProvider = Provider.of<AdminJobProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_job?.jobTitle ?? 'تفاصيل فرصة العمل'),
        actions: [
          if (_job != null) ...[ // عرض الأزرار فقط إذا تم جلب الفرصة بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : () { // تعطيل الزر أثناء التحميل
                // الانتقال إلى شاشة تعديل فرصة عمل
                print('Edit Job Tapped for job ID ${widget.jobId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditJobScreen(job: _job!), // <--- تمرير كائن الوظيفة للشاشة الجديدة
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteJob, // تعطيل الزر أثناء التحميل
            ),
            // أضف زر لعرض المتقدمين لهذه الوظيفة (الأدمن والمدير يمكنهم ذلك)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'عرض المتقدمين',
              onPressed: _isLoading ? null : () {
                print('View Applicants Tapped for job ID ${widget.jobId}');
                if (_job?.jobId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminJobApplicantsScreen(jobId: _job!.jobId!) // <--- الانتقال لشاشة المتقدمين
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('معرف الوظيفة غير متاح لعرض المتقدمين.')),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading && _job == null // حالة التحميل الأولية فقط
          ? const Center(child: CircularProgressIndicator())
          : _jobError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: $_jobError'))
          : _job == null // بيانات الوظيفة غير موجودة بعد التحميل (وإذا لا يوجد خطأ، هذا يعني 404 من API)
          ? const Center(child: Text('فرصة العمل غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل فرصة العمل (مشابه لشاشة التفاصيل العامة، مع تفاصيل خاصة بالمدير/الأدمن)
            Text(
              _job!.jobTitle ?? 'بدون عنوان',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('الناشر UserID: ${_job!.userId ?? 'غير محدد'}', style: const TextStyle(fontSize: 16)), // خاص بالمدير/الأدمن
            Text(
              'النوع: ${_job!.type ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'الحالة: ${_job!.status ?? 'غير محدد'}',
              style: TextStyle(fontSize: 16, color: _job!.status == 'مفعل' ? Colors.green : Colors.orange),
            ),
            Text(
              'المكان: ${_job!.site ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'تاريخ النشر: ${_job!.date?.toString().split(' ')[0] ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 14),
            ),
            if (_job!.endDate != null)
              Text(
                'تاريخ الانتهاء: ${_job!.endDate!.toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 16),
            const Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_job!.jobDescription ?? 'لا يوجد وصف.', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (_job!.qualification != null && _job!.qualification!.isNotEmpty) ...[
              const Text('المؤهلات المطلوبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_job!.qualification!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],
            if (_job!.skills != null && _job!.skills!.isNotEmpty) ...[
              const Text('المهارات المطلوبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_job!.skills!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],
            // TODO: عرض قائمة المتقدمين لهذه الوظيفة إذا كانت البيانات محملة (تتطلب JobApplicantsProvider)
            // (تم إضافة زر للانتقال لشاشة المتقدمين)
          ],
        ),
      ),
    );
  }

  // Implement _deleteJob method with AlertDialog confirmation
  Future<void> deleteJob(BuildContext context) async {
    if (_job?.jobId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف فرصة العمل "${_job!.jobTitle ?? 'بدون عنوان'}"؟'),
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; _jobError = null; }); // Start loading state for action
      final provider = Provider.of<AdminJobProvider>(context, listen: false);
      try {
        await provider.deleteJob(context, _job!.jobId!);
        Navigator.pop(context); // Go back after successful deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف فرصة العمل بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) { e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}')); }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حذف فرصة العمل: ${e.toString()}')));
      } finally {
        setState(() { _isLoading = false; }); // End loading state
      }
    }
  }
}

// Simple extension for List<JobOpportunity> if not available elsewhere
extension ListJobExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// TODO: أنشئ شاشة ApplicantDetailScreen لعرض تفاصيل المتقدم (بياناته، ملفه الشخصي، خيارات لتغيير حالة طلبه)
// Note: ApplicantDetailScreen will need JobApplicantsProvider or similar to fetch single applicant details if not passed fully.