import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_company_provider.dart'; // لتنفيذ عمليات CRUD
import '../models/company.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO المطلوبة
import 'admin_company_detail_screen.dart'; // شاشة التفاصيل
import 'create_edit_company_screen.dart'; // <--- شاشة إضافة/تعديل الشركة


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
    // جلب قائمة الشركات عند تهيئة الشاشة
    Provider.of<AdminCompanyProvider>(context, listen: false).fetchAllCompanies(context);

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق من أن هناك المزيد لتحميله ومن أننا لسنا بصدد جلب بالفعل
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !Provider.of<AdminCompanyProvider>(context, listen: false).isFetchingMore &&
          Provider.of<AdminCompanyProvider>(context, listen: false).hasMorePages) {
        Provider.of<AdminCompanyProvider>(context, listen: false).fetchMoreCompanies(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // تابع لحذف شركة
  Future<void> _deleteCompany(int companyId) async {
    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه الشركة؟'), // يمكنك عرض اسم الشركة هنا إذا كان متاحاً بسهولة
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه
      final provider = Provider.of<AdminCompanyProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteCompany(context, companyId);
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الشركة بنجاح.')),
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
          SnackBar(content: Text('فشل حذف الشركة: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final companyProvider = Provider.of<AdminCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الشركات'),
        actions: [
          // زر إضافة شركة جديدة
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // الانتقال إلى شاشة إضافة شركة جديدة (CreateEditCompanyScreen)
              print('Add Company Tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  // نمرر null لـ company للإشارة إلى أنها شاشة إضافة
                  builder: (context) => const CreateEditCompanyScreen(company: null),
                ),
              );
            },
          ),
        ],
      ),
      body: companyProvider.isLoading && companyProvider.companies.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : companyProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${companyProvider.error}'))
          : companyProvider.companies.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لا توجد شركات متاحة.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: companyProvider.companies.length + (companyProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == companyProvider.companies.length) {
            // إذا كنا في حالة جلب المزيد، اعرض مؤشر
            return companyProvider.isFetchingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(); // وإلا لا تعرض شيئاً
          }

          final company = companyProvider.companies[index];
          // تأكد أن الشركة لديها ID قبل عرض أزرار التعديل/الحذف أو الانتقال
          if (company.companyId == null) return const SizedBox.shrink();

          return ListTile(
              title: Text(company.name ?? 'بدون اسم'),
              subtitle: Text('المدير UserID: ${company.userId ?? 'غير محدد'} - الحالة: ${company.status ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر تعديل شركة
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'تعديل',
                    onPressed: companyProvider.isLoading ? null : () { // تعطيل الزر أثناء تحميل أي عملية في Provider
                      // الانتقال إلى شاشة تعديل شركة
                      print('Edit Company Tapped for ID ${company.companyId}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // نمرر كائن الشركة لـ CreateEditCompanyScreen للإشارة إلى أنها شاشة تعديل
                          builder: (context) => CreateEditCompanyScreen(company: company),
                        ),
                      );
                    },
                  ),
                  // زر حذف شركة
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: companyProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                      _deleteCompany(company.companyId!); // استدعاء تابع الحذف
                    },
                  ),
                ],
              ),
              onTap: companyProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
                // الانتقال إلى شاشة تفاصيل شركة
                print('Company Tapped: ${company.companyId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminCompanyDetailScreen(companyId: company.companyId!), // <--- الانتقال لشاشة التفاصيل
                  ),
                );
              }
          );
        },
      ),
    );
  }
}

// Simple extension for List<Company>
extension ListAdminCompanyExtension on List<Company> {
  Company? firstWhereOrNull(bool Function(Company) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}