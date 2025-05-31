import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_applicants_provider.dart'; // يستخدمه المدير والأدمن لجلب المتقدمين لوظيفة
import '../models/applicant.dart';
import 'applicant_detail_screen.dart'; // تأكد من المسار
// قد تحتاج لاستيراد شاشة تفاصيل المتقدم (ApplicantDetailScreen)


class AdminJobApplicantsScreen extends StatefulWidget {
  final int jobId; // معرف الوظيفة التي سنعرض متقدميها

  const AdminJobApplicantsScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _AdminJobApplicantsScreenState createState() => _AdminJobApplicantsScreenState();
}

class _AdminJobApplicantsScreenState extends State<AdminJobApplicantsScreen> {
  // لا نحتاج ScrollController هنا لأن JobApplicantsProvider يجلب قائمة كاملة بدون Pagination حالياً
  // إذا أضفت Pagination لاحقاً ل JobApplicantsProvider، ستحتاج إضافة ScrollController ومستمع له

  @override
  void initState() {
    super.initState();
    // جلب المتقدمين للوظيفة عند تهيئة الشاشة
    // JobApplicantsProvider لديه تابع fetchApplicants يتطلب context و jobId
    Provider.of<JobApplicantsProvider>(context, listen: false).fetchApplicants(context, widget.jobId);
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final applicantsProvider = Provider.of<JobApplicantsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتقدمون للوظيفة'), // يمكنك عرض اسم الوظيفة هنا أيضاً إذا مررته
      ),
      body: applicantsProvider.isLoading && applicantsProvider.applicants.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : applicantsProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${applicantsProvider.error}'))
          : applicantsProvider.applicants.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لا يوجد متقدمون لهذه الوظيفة حالياً.'))
          : ListView.builder(
        // لا يوجد ScrollController هنا حالياً
        itemCount: applicantsProvider.applicants.length,
        itemBuilder: (context, index) {
          // عرض بيانات المتقدم
          final applicant = applicantsProvider.applicants[index];
          // تأكد من وجود بيانات المستخدم المدمجة
          final applicantUser = applicant.user;

          return ListTile(
            title: Text('${applicantUser?.firstName ?? ''} ${applicantUser?.lastName ?? ''} (${applicantUser?.username ?? ''})'), // اسم المتقدم واسم المستخدم
            subtitle: Text('حالة الطلب: ${applicant.status ?? 'غير محدد'} - تاريخ التقديم: ${applicant.date?.toString().split(' ')[0] ?? ''}'), // حالة الطلب وتاريخ التقديم
            // يمكن إضافة أيقونات أو معلومات إضافية هنا

            onTap: () {
              // الانتقال إلى شاشة تفاصيل المتقدم
              print('Applicant tapped: ${applicantUser?.username}');
              // تأكد أن كائن المستخدم موجود قبل الانتقال
              if (applicantUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplicantDetailScreen(applicant: applicant), // <--- تمرير كائن Applicant بالكامل
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
    );
  }
}