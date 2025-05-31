import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/applicant.dart'; // نمرر كائن المتقدم
import '../models/user.dart'; // لاستخدام بيانات المستخدم
import '../models/profile.dart'; // لاستخدام بيانات الملف الشخصي
import '../services/api_service.dart'; // لاستخدام ApiException
import '../providers/job_applicants_provider.dart'; // لتحديث حالة الطلب (للمدير)
// import '../providers/admin_job_provider.dart'; // لتحديث حالة الطلب (للأدمن إذا كانت منفصلة)
import '../providers/auth_provider.dart'; // لمعرفة نوع المستخدم وصلاحياته


class ApplicantDetailScreen extends StatefulWidget {
  final Applicant applicant; // كائن المتقدم الذي تم النقر عليه في القائمة

  const ApplicantDetailScreen({Key? key, required this.applicant}) : super(key: key);

  @override
  _ApplicantDetailScreenState createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  String? _currentStatus; // لتخزين حالة الطلب الحالية
  bool _isUpdatingStatus = false; // لحالة التحميل عند تحديث الحالة

  // قائمة الحالات المتاحة لتحديث الطلب (تأكد من تطابقها مع Backend)
  final List<String> _availableStatuses = ['Pending', 'Reviewed', 'Shortlisted', 'Accepted', 'Rejected'];


  @override
  void initState() {
    super.initState();
    _currentStatus = widget.applicant.status; // تعيين الحالة الافتراضية من الكائن الممرر
    // في حالات معقدة، قد تحتاج هنا لجلب تفاصيل المستخدم (الملف الشخصي، المهارات) بالكامل
    // إذا لم تكن محملة بالكامل في كائن Applicant الممرر.
    // بناءً على موديل Applicant لدينا، يتم تحميل User بالكامل مع profile فيه، لذا قد لا تحتاج جلب إضافي.
  }

  // تابع لتحديث حالة الطلب
  Future<void> _updateStatus(String newStatus) async {
    setState(() { _isUpdatingStatus = true; });
    // تحديد Provider المناسب بناءً على نوع المستخدم الحالي
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final User? currentUser = authProvider.user;

    if (currentUser == null) {
      setState(() { _isUpdatingStatus = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: بيانات المستخدم غير متوفرة.')),
      );
      return;
    }

    try {
      // TODO: استدعاء تابع تحديث الحالة في JobApplicantsProvider (أو AdminJobProvider)
      // التابع updateApplicantStatus في ApiService يتطلب token, applicationId, newStatus
      // يجب أن يكون هناك تابع في Provider يستدعي ApiService
      // مثال (إذا كان التابع اسمه updateApplicantStatus في JobApplicantsProvider):
      // await Provider.of<JobApplicantsProvider>(context, listen: false).updateApplicantStatus(context, widget.applicant.id!, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updating status to $newStatus...')),
      );

      // محاكاة تحديث ناجح محلياً (استبدله بالاستدعاء الفعلي)
      await Future.delayed(const Duration(seconds: 1)); // محاكاة انتظار API

      setState(() {
        _currentStatus = newStatus; // تحديث الحالة في الواجهة
        _isUpdatingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة الطلب إلى $newStatus.')),
      );

    } on ApiException catch (e) {
      setState(() { _isUpdatingStatus = false; });
      String errorMessage = 'فشل التحديث: ${e.message}';
      if (e.errors != null) {
        e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      setState(() { _isUpdatingStatus = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث الحالة: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع لـ provider هنا إلا لحالة التحميل عند تحديث الحالة (_isUpdatingStatus)


    final applicantUser = widget.applicant.user; // بيانات المستخدم المتقدم
    final applicantProfile = applicantUser?.profile; // بيانات ملفه الشخصي

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المتقدم: ${applicantUser?.username ?? 'غير معروف'}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('معلومات الطلب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('معرف الطلب: ${widget.applicant.id ?? 'غير متوفر'}'),
            Text('حالة الطلب: ${_currentStatus ?? 'غير محدد'}'), // عرض الحالة الحالية
            Text('تاريخ التقديم: ${widget.applicant.date?.toString().split(' ')[0] ?? 'غير معروف'}'),
            if (widget.applicant.description != null) Text('ملاحظات المتقدم: ${widget.applicant.description!}'),
            if (widget.applicant.cv != null) Text('مسار السيرة الذاتية: ${widget.applicant.cv!}'), // يمكن إضافة زر لفتح أو تحميل السيرة الذاتية
            const Divider(height: 24),

            const Text('معلومات المتقدم (المستخدم):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (applicantUser == null)
              const Text('بيانات المستخدم غير متوفرة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (applicantUser != null) ...[
              Text('الاسم: ${applicantUser.firstName ?? ''} ${applicantUser.lastName ?? ''}'),
              Text('اسم المستخدم: ${applicantUser.username ?? ''}'),
              Text('البريد الإلكتروني: ${applicantUser.email ?? ''}'),
              if (applicantUser.phone != null) Text('رقم الهاتف: ${applicantUser.phone!}'),
              // يمكن عرض المزيد من تفاصيل المستخدم
            ],
            const Divider(height: 24),

            const Text('الملف الشخصي للمتقدم:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (applicantProfile == null)
              const Text('بيانات الملف الشخصي غير متوفرة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (applicantProfile != null) ...[
              if (applicantProfile.university != null) Text('الجامعة: ${applicantProfile.university!}'),
              if (applicantProfile.gpa != null) Text('المعدل التراكمي: ${applicantProfile.gpa!}'),
              if (applicantProfile.personalDescription != null) Text('نبذة شخصية: ${applicantProfile.personalDescription!}'),
              if (applicantProfile.technicalDescription != null) Text('نبذة اختصاصية: ${applicantProfile.technicalDescription!}'),
              if (applicantProfile.gitHyperLink != null) Text('رابط GitHub: ${applicantProfile.gitHyperLink!}'),
              // يمكن عرض المزيد من تفاصيل الملف الشخصي
            ],
            const Divider(height: 24),

            // عرض المهارات للمتقدم إذا كانت محملة
            const Text('مهارات المتقدم:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (applicantUser?.skills == null || applicantUser!.skills!.isEmpty)
              const Text('المهارات غير متوفرة أو لم يتم إضافتها.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (applicantUser?.skills != null && applicantUser!.skills!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: applicantUser.skills!.map((skill) => Chip(
                  label: Text('${skill.name ?? 'غير معروف'} (${skill.pivot?.stage ?? 'غير محدد'})'),
                )).toList(),
              ),
            const Divider(height: 24),

            // خيارات تحديث الحالة (خاصة بالمدير أو الأدمن)
            const Text('تحديث حالة الطلب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isUpdatingStatus) // استخدام حالة التحميل الخاصة بالتحديث هنا
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'الحالة الجديدة'),
                value: _currentStatus,
                items: _availableStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null && newValue != _currentStatus) {
                    // استدعاء تابع التحديث عند اختيار حالة جديدة
                    _updateStatus(newValue);
                  }
                },
              ),

          ],
        ),
      ),
    );
  }
}