import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_company_provider.dart'; // تأكد من المسار
import '../models/company.dart';
import 'admin_company_detail_screen.dart'; // تأكد من المسار
// يمكنك استيراد شاشة إضافة/تعديل شركة أو شاشة تفاصيل هنا

class AdminCompaniesListScreen extends StatefulWidget {
  const AdminCompaniesListScreen({Key? key}) : super(key: key);

  @override
  _AdminCompaniesListScreenState createState() => _AdminCompaniesListScreenState();
}

class _AdminCompaniesListScreenState extends State<AdminCompaniesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<AdminCompanyProvider>(context, listen: false).fetchAllCompanies(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<AdminCompanyProvider>(context, listen: false).fetchMoreCompanies(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // TODO: تابع لحذف شركة (adminCompanyProvider.deleteCompany) مع تأكيد

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<AdminCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الشركات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة شركة جديدة (CreateEditCompanyScreen)
              print('Add Company Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة شركة لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: companyProvider.isLoading && companyProvider.companies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : companyProvider.error != null
          ? Center(child: Text('Error: ${companyProvider.error}'))
          : companyProvider.companies.isEmpty
          ? const Center(child: Text('لا توجد شركات متاحة.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: companyProvider.companies.length + (companyProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == companyProvider.companies.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final company = companyProvider.companies[index];
          return ListTile(
              title: Text(company.name ?? 'بدون اسم'),
              subtitle: Text('المدير UserID: ${company.userId ?? 'غير محدد'} - الحالة: ${company.status ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'تعديل',
                    onPressed: () {
                      // TODO: الانتقال إلى شاشة تعديل شركة (CreateEditCompanyScreen) مع تمرير بيانات الشركة
                      print('Edit Company Tapped for ID ${company.companyId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('وظيفة تعديل شركة لم تنفذ.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: () {
                      if (company.companyId != null) {
                        // TODO: تابع لحذف الشركة (adminCompanyProvider.deleteCompany) مع تأكيد
                        print('Delete Company Tapped for ID ${company.companyId}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('وظيفة حذف شركة لم تنفذ.')),
                        );
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                // TODO: الانتقال إلى شاشة تفاصيل شركة (AdminCompanyDetailScreen)
                print('Company Tapped: ${company.companyId}');
                 Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCompanyDetailScreen(companyId: company.companyId!)));
              }
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateEditCompanyScreen لإضافة أو تعديل شركة (تحتاج AdminCompanyProvider.createCompany و .updateCompany)
// TODO: أنشئ شاشة AdminCompanyDetailScreen إذا لزم الأمر لعرض تفاصيل شركة (تحتاج AdminCompanyProvider.fetchCompany إذا أضفت التابع للـ Provider)