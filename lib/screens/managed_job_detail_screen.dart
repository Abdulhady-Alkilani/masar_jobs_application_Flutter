import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_job_opportunity_provider.dart'; // لجلب وتحديث الوظيفة
import '../providers/job_applicants_provider.dart'; // لجلب المتقدمين
import '../models/job_opportunity.dart'; // تأكد من المسار
import '../models/applicant.dart'; // لعرض المتقدمين
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات الـ TODO
import 'edit_job_screen.dart'; // <--- تأكد من المسار
import 'applicant_detail_screen.dart'; // <--- تأكد من المسار


class ManagedJobDetailScreen extends StatefulWidget {
  final int jobId;

  const ManagedJobDetailScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _ManagedJobDetailScreenState createState() => _ManagedJobDetailScreenState();
}

class _ManagedJobDetailScreenState extends State<ManagedJobDetailScreen> {
  JobOpportunity? _job; // لتخزين بيانات الوظيفة الفردية
  String? _jobError; // لتخزين خطأ جلب الوظيفة
  bool _isLoading = false; // حالة تحميل خاصة بالشاشة عند جلب البيانات أو تنفيذ إجراء

  @override
  void initState() {
    super.initState();
    _fetchJobAndApplicants();
  }

  // تابع لجلب تفاصيل الوظيفة والمتقدمين لها
  Future<void> _fetchJobAndApplicants() async {
    setState(() { _isLoading = true; _jobError = null; });
    final jobProvider = Provider.of<ManagedJobOpportunityProvider>(context, listen: false);
    final applicantsProvider = Provider.of<JobApplicantsProvider>(context, listen: false);

    try {
      // **الطريقة الأبسط (اعتمادًا على القائمة المحملة):**
      // ابحث عن الوظيفة في القائمة المحملة بواسطة ManagedJobOpportunityProvider
      JobOpportunity? fetchedJob = ListJobExtension(jobProvider.managedJobs).firstWhereOrNull((j) => j.jobId == widget.jobId);

      if (fetchedJob != null) {
        // إذا وجد في القائمة، استخدم بياناته
        setState(() {
          _job = fetchedJob;
          _jobError = null;
        });
      } else {
        // إذا لم يُعثر عليه في القائمة (مثال: لم يتم جلب القائمة بعد، أو الوظيفة في صفحة أخرى)
        // **TODO: الطريقة الأفضل هي إضافة تابع fetchSingleManagedJob(BuildContext context, int jobId) في ManagedJobOpportunityProvider و ApiService.**
        // هذا التابع سيجلب وظيفة واحدة خاصة بالمدير مباشرة من API.
        // For now, as a simple fallback, show an error or try to refetch the main list (less efficient).
        // Let's just indicate it wasn't found in the currently loaded list.
        setState(() {
          _job = null;
          _jobError = 'الوظيفة بمعرف ${widget.jobId} غير موجودة في القائمة المحملة حالياً.';
        });
      }


      // إذا تم جلب الوظيفة (سواء من القائمة أو بتابع مخصص لاحقاً)، جلب المتقدمين لها
      if (_job != null) {
        await applicantsProvider.fetchApplicants(context, widget.jobId);
      }


    } on ApiException catch (e) {
      setState(() {
        _job = null;
        _jobError = 'فشل جلب بيانات الوظيفة أو المتقدمين: ${e.message}';
        // إذا كان الخطأ 404 من جلب المتقدمين، قد لا يكون خطأ فادحاً، فقط لا يوجد متقدمون
      });
      // يمكن معالجة أخطاء JobApplicantsProvider بشكل منفصل لاحقاً
    } catch (e) {
      setState(() {
        _job = null;
        _jobError = 'فشل جلب بيانات الوظيفة أو المتقدمين: ${e.toString()}';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // تابع لحذف الوظيفة
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

      final provider = Provider.of<ManagedJobOpportunityProvider>(context, listen: false);
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
    // هنا نستمع للـ JobApplicantsProvider فقط لأن حالته (isLoading, error, applicants) تتغير بشكل منفصل بعد جلب الوظيفة
    final applicantsProvider = Provider.of<JobApplicantsProvider>(context);


    return Scaffold(
      appBar: AppBar(
        title: Text(_job?.jobTitle ?? 'تفاصيل الوظيفة'),
        actions: [
          if (_job != null) ...[ // عرض الأزرار فقط إذا تم جلب الوظيفة بنجاح
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
            // TODO: أضف زر لعرض المتقدمين إذا كان هذا متاحاً للمدير هنا
            // (بيانات المتقدمين يتم جلبها وعرضها في نفس الشاشة حالياً)
          ],
        ],
      ),
      body: _isLoading && _job == null && applicantsProvider.isLoading == false // حالة التحميل الأولية للوظيفة (تجنب عرض مؤشر أثناء جلب المتقدمين بعد جلب الوظيفة)
          ? const Center(child: CircularProgressIndicator())
          : _jobError != null // خطأ جلب بيانات الوظيفة
          ? Center(child: Text('Error: $_jobError'))
          : _job == null // بيانات الوظيفة غير موجودة بعد التحميل (وإذا لا يوجد خطأ، هذا يعني 404 من API)
          ? const Center(child: Text('فرصة العمل غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل فرصة العمل (مشابه لشاشة التفاصيل العامة، مع تفاصيل خاصة بالمدير)
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
            const Divider(height: 32),

            const Text('المتقدمون:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            applicantsProvider.isLoading // حالة تحميل المتقدمين
                ? const Center(child: CircularProgressIndicator())
                : applicantsProvider.error != null // خطأ في جلب المتقدمين
                ? Center(child: Text('Error loading applicants: ${applicantsProvider.error}'))
                : applicantsProvider.applicants.isEmpty // لا يوجد متقدمون
                ? const Center(child: Text('لا يوجد متقدمون حالياً لهذه الوظيفة.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applicantsProvider.applicants.length,
              itemBuilder: (context, index) {
                final applicant = applicantsProvider.applicants[index];
                return ListTile(
                  title: Text('${applicant.user?.firstName ?? ''} ${applicant.user?.lastName ?? ''} (${applicant.user?.username ?? ''})'), // عرض اسم المستخدم واسم المستخدم
                  subtitle: Text('حالة الطلب: ${applicant.status ?? 'غير محدد'}'),
                  trailing: Text(applicant.date?.toString().split(' ')[0] ?? ''),
                  onTap: () {
                    // الانتقال إلى شاشة تفاصيل المتقدم
                    print('Applicant tapped: ${applicant.user?.username}');
                    if (applicant.user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ApplicantDetailScreen(applicant: applicant) // <--- تمرير كائن Applicant
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('بيانات المتقدم غير متاحة.')),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// TODO: أضف Implement _deleteJob method with AlertDialog confirmation
// تم وضع هيكلها في الخطوة السابقة، قم بتنفيذها الآن
/*
   Future<void> _deleteJob(BuildContext context) async { ... }
   */
}

// Simple extension for List<JobOpportunity>
extension ListJobExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}