import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_company_provider.dart';
import '../models/company.dart';
// استيراد شاشات إدارة موارد الشركة
import 'edit_company_screen.dart';
import 'managed_jobs_list_screen.dart'; // تأكد من المسار
import 'managed_courses_list_screen.dart'; // تأكد من المسار


class ManagedCompanyScreen extends StatefulWidget {
  const ManagedCompanyScreen({Key? key}) : super(key: key);

  @override
  _ManagedCompanyScreenState createState() => _ManagedCompanyScreenState();
}

class _ManagedCompanyScreenState extends State<ManagedCompanyScreen> {
  @override
  void initState() {
    super.initState();
    // جلب بيانات الشركة عند الدخول للشاشة
    Provider.of<ManagedCompanyProvider>(context, listen: false).fetchManagedCompany(context);
  }

  // TODO: تابع لتحديث بيانات الشركة (يستدعي managedCompanyProvider.updateManagedCompany)

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<ManagedCompanyProvider>(context);
    final company = companyProvider.company;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شركتي'),
        actions: [
          if (company != null) // عرض زر التعديل فقط إذا وجدت الشركة
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: الانتقال إلى شاشة تعديل الشركة (EditCompanyScreen) أو فتح نموذج
                print('Edit Company Tapped');
                 Navigator.push(context, MaterialPageRoute(builder: (context) => EditCompanyScreen(company: company)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('وظيفة تعديل الشركة لم تنفذ.')),
                );
              },
            ),
        ],
      ),
      body: companyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : companyProvider.error != null
          ? Center(child: Text('Error: ${companyProvider.error}'))
          : company == null // لا توجد شركة مرتبطة بالمدير
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('لا توجد شركة مرتبطة بحسابك.'),
            const SizedBox(height: 16),
            // TODO: عرض زر لطلب إنشاء شركة جديدة (إذا كان هذا السيناريو مسموحاً للمدير)
            // (API doc تشير إلى أن Admin هو من ينشئ الشركة أو يوافق على الطلبات)
            // إذا كان المدير يبدأ بطلب، هذا يحتاج workflow مختلف.
            // إذا كان Admin هو من يربط الشركة بالمدير، هذه الشاشة فقط للعرض/التعديل.
            // For now, assume Admin creates/links.
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name ?? 'اسم الشركة غير معروف', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (company.status != null) Text('الحالة: ${company.status!}', style: TextStyle(fontSize: 16, color: company.status == 'approved' ? Colors.green : Colors.orange)),
            const Divider(height: 24),
            if (company.description != null) ...[
              const Text('عن الشركة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(company.description!),
              const SizedBox(height: 16),
            ],
            if (company.email != null) Text('البريد الإلكتروني: ${company.email!}'),
            if (company.phone != null) Text('رقم الهاتف: ${company.phone!}'),
            if (company.country != null) Text('الدولة: ${company.country!}'),
            if (company.city != null) Text('المدينة: ${company.city!}'),
            if (company.detailedAddress != null) Text('العنوان المفصل: ${company.detailedAddress!}'),
            if (company.webSite != null) Text('الموقع الإلكتروني: ${company.webSite!}'),
            // TODO: عرض روابط الوسائط (Media) إذا كانت موجودة

            const Divider(height: 32),
            const Text('إدارة الموارد:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('فرص العمل التي نشرتها'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedJobsListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('الدورات التدريبية التي نشرتها'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedCoursesListScreen()));
              },
            ),
            // يمكنك إضافة المزيد من الروابط لإدارة المتقدمين/المسجلين من هنا أو من شاشات الوظائف/الدورات الفردية
          ],
        ),
      ),
    );
  }
}

// TODO: أنشئ شاشة EditCompanyScreen لتعديل بيانات الشركة