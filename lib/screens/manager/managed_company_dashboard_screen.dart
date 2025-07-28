// lib/screens/manager/managed_company_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/managed_company_provider.dart';
import 'edit_company_screen.dart'; // شاشة تعديل الشركة
import 'create_company_request_screen.dart'; // شاشة إنشاء طلب
import '../../widgets/rive_loading_indicator.dart';

class ManagedCompanyDashboardScreen extends StatefulWidget {
  const ManagedCompanyDashboardScreen({super.key});

  @override
  State<ManagedCompanyDashboardScreen> createState() => _ManagedCompanyDashboardScreenState();
}

class _ManagedCompanyDashboardScreenState extends State<ManagedCompanyDashboardScreen> {

  @override
  void initState() {
    super.initState();
    // جلب بيانات الشركة عند فتح الشاشة لأول مرة
    // استخدام addPostFrameCallback يضمن أن context متاح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManagedCompanyProvider>(context, listen: false).fetchManagedCompany(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ManagedCompanyProvider>(
        builder: (context, companyProvider, child) {
          if (companyProvider.isLoading) {
            return const Center(child: RiveLoadingIndicator());
          }

          if (companyProvider.error != null) {
            return Center(
              child: Text('حدث خطأ: ${companyProvider.error}'),
            );
          }

          // الحالة 1: لا توجد شركة مرتبطة بالمدير
          if (!companyProvider.hasCompany) {
            return _buildNoCompanyView(context);
          }

          // الحالة 2: توجد شركة
          final company = companyProvider.company!;
          return RefreshIndicator(
            onRefresh: () => companyProvider.fetchManagedCompany(context),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCompanyHeader(context, company),
                const SizedBox(height: 24),
                _buildCompanyDetailsCard(company),
                const SizedBox(height: 24),
                // يمكنك إضافة إحصائيات هنا (عدد الوظائف، المتقدمين، إلخ)
                // Text('إحصائيات سريعة', style: Theme.of(context).textTheme.titleLarge),
                // const SizedBox(height: 16),
                // GridView(...)
              ],
            ),
          );
        },
      ),
    );
  }

  // واجهة في حالة عدم وجود شركة
  Widget _buildNoCompanyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا توجد شركة مرتبطة بحسابك بعد.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك إرسال طلب لإنشاء شركة جديدة وستتم مراجعته من قبل الإدارة.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('إنشاء طلب شركة'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCompanyRequestScreen()));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // واجهة عرض معلومات الشركة
  Widget _buildCompanyHeader(BuildContext context, company) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          // backgroundImage: NetworkImage(company.logoUrl ?? ''),
          child: const Icon(Icons.business, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(company.name ?? 'اسم الشركة', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Chip(
          label: Text(company.status ?? 'غير معروف'),
          backgroundColor: company.status == 'approved' ? Colors.green.shade100 : Colors.orange.shade100,
          labelStyle: TextStyle(color: company.status == 'approved' ? Colors.green.shade800 : Colors.orange.shade800),
        ),
      ],
    );
  }

  Widget _buildCompanyDetailsCard(company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('تعديل بيانات الشركة'),
              leading: const Icon(Icons.edit_note),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EditCompanyScreen(key: company)));
              },
            ),
            const Divider(),
            _buildDetailRow(Icons.email_outlined, 'البريد الإلكتروني', company.email ?? 'لا يوجد'),
            _buildDetailRow(Icons.phone_outlined, 'الهاتف', company.phone ?? 'لا يوجد'),
            _buildDetailRow(Icons.location_on_outlined, 'الموقع', '${company.city ?? ''}, ${company.country ?? ''}'),
            _buildDetailRow(Icons.link, 'الموقع الإلكتروني', company.webSite ?? 'لا يوجد'),
            const SizedBox(height: 16),
            const Text('الوصف:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(company.description ?? 'لا يوجد وصف للشركة.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}

// ملاحظة: تأكد من وجود شاشة EditCompanyScreen أو أنشئها.