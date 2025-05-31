import 'package:flutter/material.dart';
import '../models/enrollee.dart'; // نمرر كائن المسجل
import '../models/user.dart'; // لاستخدام بيانات المستخدم
import '../models/profile.dart';
import '../services/api_service.dart'; // لاستخدام بيانات الملف الشخصي
// قد تحتاج لاستيراد Providers لتحديث حالة التسجيل (ManagedTrainingCourseProvider أو CourseEnrolleesProvider أو AdminCourseProvider)
// وقد تحتاج AuthProvider للحصول على التوكن ومعرفة نوع المستخدم

class EnrolleeDetailScreen extends StatefulWidget {
  final Enrollee enrollee; // كائن المسجل الذي تم النقر عليه في القائمة

  const EnrolleeDetailScreen({Key? key, required this.enrollee}) : super(key: key);

  @override
  _EnrolleeDetailScreenState createState() => _EnrolleeDetailScreenState();
}

class _EnrolleeDetailScreenState extends State<EnrolleeDetailScreen> {
  String? _currentStatus; // لتخزين حالة التسجيل الحالية
  bool _isUpdatingStatus = false; // لحالة التحميل عند تحديث الحالة

  // TODO: قائمة الحالات المتاحة لتحديث التسجيل (يجب أن تأتي من Backend أو ثابت هنا)
  final List<String> _availableStatuses = ['مكتمل', 'قيد التقدم', 'ملغي']; // مثال للحالات

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.enrollee.status; // تعيين الحالة الافتراضية من الكائن الممرر
    // إذا كانت بيانات المستخدم/الملف الشخصي/المهارات غير محملة بالكامل في كائن Enrollee الممرر،
    // ستحتاج لجلبها هنا باستخدام Provider للمستخدم.
  }

  // تابع لتحديث حالة التسجيل
  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    setState(() { _isUpdatingStatus = true; });
    // تحديد Provider المناسب بناءً على نوع المستخدم الحالي المستدعي للعملية
    // مثلاً: إذا كان المدير يستخدم ManagedTrainingCourseProvider، الاستشاري يستخدم ConsultantCourseProvider، الأدمن يستخدم AdminCourseProvider
    // وكل منهم لديه تابع لتحديث حالة التسجيل
    // للتبسيط، سنفترض وجود تابع مشترك أو نستخدم JobApplicantsProvider الذي لديه updateEnrolleeStatus

    try {
      // TODO: استدعاء تابع تحديث الحالة في Provider المناسب (ManagedTrainingCourseProvider أو CourseEnrolleesProvider أو AdminCourseProvider)
      // التابع updateEnrollmentStatus في ApiService يتطلب token, enrollmentId, newStatus, completionDate
      // يجب أن يكون هناك تابع في Provider يستدعي ApiService
      // مثال (إذا كان التابع اسمه updateEnrollmentStatus في CourseEnrolleesProvider):
      // await Provider.of<CourseEnrolleesProvider>(context, listen: false).updateEnrollmentStatus(context, widget.enrollee.enrollmentId!, newStatus, completionDate: newStatus == 'مكتمل' ? DateTime.now() : null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updating status to $newStatus...')),
      );

      // محاكاة تحديث ناجح محلياً (استبدله بالاستدعاء الفعلي)
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _currentStatus = newStatus; // تحديث الحالة في الواجهة
        _isUpdatingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة التسجيل إلى $newStatus.')),
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
    // لا نحتاج للاستماع للـ provider هنا إلا لحالة التحميل عند تحديث الحالة (_isUpdatingStatus)


    final enrolleeUser = widget.enrollee.user; // بيانات المستخدم المسجل
    final enrolleeProfile = enrolleeUser?.profile; // بيانات ملفه الشخصي

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المسجل: ${enrolleeUser?.username ?? 'غير معروف'}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('معلومات التسجيل:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('معرف التسجيل: ${widget.enrollee.enrollmentId ?? 'غير متوفر'}'),
            Text('حالة التسجيل: ${_currentStatus ?? 'غير محدد'}'), // عرض الحالة الحالية
            Text('تاريخ التسجيل: ${widget.enrollee.date?.toString().split(' ')[0] ?? 'غير معروف'}'),
            if (widget.enrollee.completDate != null) Text('تاريخ الإكمال: ${widget.enrollee.completDate!.toString().split(' ')[0]}'),
            const Divider(height: 24),

            const Text('معلومات المسجل (المستخدم):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (enrolleeUser == null)
              const Text('بيانات المستخدم غير متوفرة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (enrolleeUser != null) ...[
              Text('الاسم: ${enrolleeUser.firstName ?? ''} ${enrolleeUser.lastName ?? ''}'),
              Text('اسم المستخدم: ${enrolleeUser.username ?? ''}'),
              Text('البريد الإلكتروني: ${enrolleeUser.email ?? ''}'),
              if (enrolleeUser.phone != null) Text('رقم الهاتف: ${enrolleeUser.phone!}'),
              // يمكن عرض المزيد من تفاصيل المستخدم
            ],
            const Divider(height: 24),

            const Text('الملف الشخصي للمسجل:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (enrolleeProfile == null)
              const Text('بيانات الملف الشخصي غير متوفرة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (enrolleeProfile != null) ...[
              if (enrolleeProfile.university != null) Text('الجامعة: ${enrolleeProfile.university!}'),
              if (enrolleeProfile.gpa != null) Text('المعدل التراكمي: ${enrolleeProfile.gpa!}'),
              if (enrolleeProfile.personalDescription != null) Text('نبذة شخصية: ${enrolleeProfile.personalDescription!}'),
              if (enrolleeProfile.technicalDescription != null) Text('نبذة اختصاصية: ${enrolleeProfile.technicalDescription!}'),
              if (enrolleeProfile.gitHyperLink != null) Text('رابط GitHub: ${enrolleeProfile.gitHyperLink!}'),
              // يمكن عرض المزيد من تفاصيل الملف الشخصي
            ],
            const Divider(height: 24),

            // TODO: عرض المهارات للمسجل إذا كانت محملة في كائن المستخدم الممرر (enrolleeUser.skills)
            const Text('مهارات المسجل:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (enrolleeUser?.skills == null || enrolleeUser!.skills!.isEmpty)
              const Text('المهارات غير متوفرة أو لم يتم إضافتها.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (enrolleeUser?.skills != null && enrolleeUser!.skills!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: enrolleeUser.skills!.map((skill) => Chip(
                  label: Text('${skill.name ?? 'غير معروف'} (${skill.pivot?.stage ?? 'غير محدد'})'),
                )).toList(),
              ),
            const Divider(height: 24),

            // خيارات تحديث الحالة (خاصة بالمدير أو الاستشاري أو الأدمن)
            const Text('تحديث حالة التسجيل:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isUpdatingStatus) // استخدام حالة التحميل الخاصة بالتحديث هنا
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'الحالة الجديدة'),
                value: _currentStatus,
                items: [
                  // إضافة خيار null (اختياري إذا كان backend يسمح بذلك)
                  // const DropdownMenuItem<String>(value: null, child: Text('غير محدد')),
                  // إضافة الحالات المتاحة
                  ..._availableStatuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                ],
                onChanged: (newValue) {
                  if (newValue != null && newValue != _currentStatus) {
                    // استدعاء تابع التحديث عند اختيار حالة جديدة
                    _updateStatus(context, newValue); // تمرير context
                  }
                },
              ),

          ],
        ),
      ),
    );
  }
}