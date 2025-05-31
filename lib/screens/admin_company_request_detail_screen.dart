import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_company_requests_provider.dart'; // للموافقة/الرفض
import '../models/company.dart'; // تأكد من المسار
import '../models/user.dart'; // تأكد من المسار (لبيانات المدير)
import '../services/api_service.dart'; // لاستخدام ApiException

class AdminCompanyRequestDetailScreen extends StatelessWidget {
  // نمرر كائن الشركة بالكامل لأنه يحتوي على بيانات المدير
  final Company companyRequest;

  const AdminCompanyRequestDetailScreen({Key? key, required this.companyRequest}) : super(key: key);

  // تابع للموافقة على الطلب
  Future<void> _approveRequest(BuildContext context) async {
    final provider = Provider.of<AdminCompanyRequestsProvider>(context, listen: false);
    try {
      // TODO: إضافة AlertDialog للتأكيد قبل الموافقة
      await provider.approveRequest(context, companyRequest.companyId!);
      // بعد النجاح، العودة للشاشة السابقة وعرض رسالة نجاح
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة على الطلب بنجاح.')),
      );
    } on ApiException catch (e) {
      String errorMessage = 'فشل الموافقة: ${e.message}';
      if (e.errors != null) {
        e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الموافقة على الطلب: ${e.toString()}')),
      );
    }
  }

  // تابع لرفض الطلب
  Future<void> _rejectRequest(BuildContext context) async {
    final provider = Provider.of<AdminCompanyRequestsProvider>(context, listen: false);
    try {
      // TODO: إضافة AlertDialog للتأكيد قبل الرفض
      await provider.rejectRequest(context, companyRequest.companyId!);
      // بعد النجاح، العودة للشاشة السابقة وعرض رسالة نجاح
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الطلب بنجاح.')),
      );
    } on ApiException catch (e) {
      String errorMessage = 'فشل الرفض: ${e.message}';
      if (e.errors != null) {
        e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفض الطلب: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إذا كنا فقط نعرض الكائن الممرر ونستدعي التوابع
    // ولكن يمكن الاستماع لحالة التحميل عند النقر على الأزرار
    final provider = Provider.of<AdminCompanyRequestsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(companyRequest.name ?? 'تفاصيل الطلب'),
      ),
      body: provider.isLoading // حالة التحميل عند الضغط على الموافقة/الرفض
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تفاصيل الشركة المقدمة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('اسم الشركة: ${companyRequest.name ?? 'غير معروف'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('معرف الشركة: ${companyRequest.companyId}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('الحالة الحالية: ${companyRequest.status ?? 'غير محدد'}', style: TextStyle(fontSize: 16, color: companyRequest.status == 'pending' ? Colors.orange : Colors.black)),
            const SizedBox(height: 8),
            if (companyRequest.description != null) Text('الوصف: ${companyRequest.description!}'),
            if (companyRequest.email != null) Text('البريد الإلكتروني: ${companyRequest.email!}'),
            if (companyRequest.phone != null) Text('رقم الهاتف: ${companyRequest.phone!}'),
            if (companyRequest.country != null) Text('الدولة: ${companyRequest.country!}'),
            if (companyRequest.city != null) Text('المدينة: ${companyRequest.city!}'),
            if (companyRequest.detailedAddress != null) Text('العنوان المفصل: ${companyRequest.detailedAddress!}'),
            if (companyRequest.webSite != null) Text('الموقع الإلكتروني: ${companyRequest.webSite!}'),
            // TODO: عرض روابط الوسائط

            const Divider(height: 24),

            const Text('معلومات المدير المقدم للطلب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (companyRequest.user == null)
              const Text('بيانات المدير غير متوفرة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (companyRequest.user != null) ...[
              Text('الاسم: ${companyRequest.user!.firstName ?? ''} ${companyRequest.user!.lastName ?? ''}'),
              Text('اسم المستخدم: ${companyRequest.user!.username ?? ''}'),
              Text('البريد الإلكتروني للمدير: ${companyRequest.user!.email ?? ''}'),
              Text('نوع الحساب: ${companyRequest.user!.type ?? ''}'),
              // يمكن عرض المزيد من تفاصيل المستخدم/المدير هنا
            ],
            const Divider(height: 24),

            // أزرار الإجراءات (عرضها فقط إذا كانت الحالة Pending)
            if (companyRequest.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : () => _approveRequest(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : () => _rejectRequest(context),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            if (companyRequest.status != 'pending')
              Center(child: Text('هذا الطلب حالته: ${companyRequest.status}', style: const TextStyle(fontStyle: FontStyle.italic))),
          ],
        ),
      ),
    );
  }
}