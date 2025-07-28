// lib/screens/admin/companies/admin_companies_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_company_provider.dart';
import '../../../models/company.dart';
import 'admin_create_edit_company_screen.dart'; // سننشئ هذه الشاشة لاحقًا
import '../../../services/api_service.dart'; // لاستخدام ApiException
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class AdminCompaniesListScreen extends StatefulWidget {
  const AdminCompaniesListScreen({super.key});

  @override
  State<AdminCompaniesListScreen> createState() => _AdminCompaniesListScreenState();
}

class _AdminCompaniesListScreenState extends State<AdminCompaniesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AdminCompanyProvider>(context, listen: false);

    // جلب الصفحة الأولى من الشركات
    provider.fetchAllCompanies(context);

    // إضافة مستمع للتمرير لجلب الصفحات التالية
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreCompanies(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // دالة لحذف شركة مع عرض مربع حوار للتأكيد
  Future<void> _deleteCompany(Company company, AdminCompanyProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف شركة "${company.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false; // إذا أغلق المستخدم الحوار، اعتبرها false

    if (confirm) {
      try {
        await provider.deleteCompany(context, company.companyId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الشركة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحذف: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الشركات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'إضافة شركة جديدة',
            onPressed: () {
              // الانتقال لشاشة الإنشاء (بدون تمرير كائن شركة)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminCreateEditCompanyScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminCompanyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.companies.isEmpty) {
            return const Center(child: RiveLoadingIndicator());
          }

          if (provider.error != null && provider.companies.isEmpty) {
            return Center(
              child: Text(
                'حدث خطأ أثناء جلب الشركات: ${provider.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (provider.companies.isEmpty) {
            return const Center(child: Text('لا توجد شركات مسجلة حاليًا.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllCompanies(context),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.companies.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // عرض مؤشر تحميل في نهاية القائمة
                if (index == provider.companies.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: RiveLoadingIndicator()),
                  );
                }
                final company = provider.companies[index];
                return _buildCompanyCard(company, provider);
              },
            ),
          );
        },
      ),
    );
  }

  // ويدجت لعرض بطاقة شركة واحدة
  Widget _buildCompanyCard(Company company, AdminCompanyProvider provider) {
    // تحديد لون الحالة
    Color statusColor;
    switch (company.status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name ?? 'اسم غير معروف',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المدير: ${company.user?.firstName ?? ''} ${company.user?.lastName ?? 'غير معروف'}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // قائمة منسدلة للإجراءات
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminCreateEditCompanyScreen(company: company),
                        ),
                      );
                    } else if (value == 'delete') {
                      _deleteCompany(company, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('تعديل')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('حذف')])),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  company.email ?? 'لا يوجد بريد إلكتروني',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    company.status ?? 'غير معروف',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}