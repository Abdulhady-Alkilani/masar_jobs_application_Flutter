import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_company_provider.dart'; // تأكد من المسار
import '../models/company.dart'; // تأكد من المسار
import 'company_detail_screen.dart'; // تأكد من المسار (شاشة تفاصيل الشركة العامة)

class PublicCompaniesListScreen extends StatefulWidget {
  const PublicCompaniesListScreen({Key? key}) : super(key: key);

  @override
  _PublicCompaniesListScreenState createState() => _PublicCompaniesListScreenState();
}

class _PublicCompaniesListScreenState extends State<PublicCompaniesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب قائمة الشركات عند تهيئة الشاشة
    Provider.of<PublicCompanyProvider>(context, listen: false).fetchCompanies();

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // المستخدم وصل لنهاية القائمة، جلب المزيد
        Provider.of<PublicCompanyProvider>(context, listen: false).fetchMoreCompanies();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final companyProvider = Provider.of<PublicCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشركات'),
      ),
      body: companyProvider.isLoading && companyProvider.companies.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : companyProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${companyProvider.error}'))
          : companyProvider.companies.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لا توجد شركات متاحة حالياً.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: companyProvider.companies.length + (companyProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == companyProvider.companies.length) {
            return const Center(child: CircularProgressIndicator());
          }

          // عرض بيانات الشركة
          final company = companyProvider.companies[index];
          return ListTile(
            title: Text(company.name ?? 'بدون اسم'),
            subtitle: Text('${company.city ?? ''}, ${company.country ?? ''}'), // مثال: الرياض، السعودية
            // يمكنك إضافة المزيد من التفاصيل هنا
            onTap: () {
              // الانتقال إلى شاشة تفاصيل الشركة
              if (company.companyId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyDetailScreen(companyId: company.companyId!),
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