// lib/screens/admin/companies/admin_company_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_company_requests_provider.dart';
import '../../../models/company.dart';
import '../../../services/api_service.dart';
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class AdminCompanyRequestsScreen extends StatefulWidget {
  const AdminCompanyRequestsScreen({super.key});

  @override
  State<AdminCompanyRequestsScreen> createState() => _AdminCompanyRequestsScreenState();
}

class _AdminCompanyRequestsScreenState extends State<AdminCompanyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminCompanyRequestsProvider>(context, listen: false).fetchCompanyRequests(context);
    });
  }

  Future<void> _handleRequest(BuildContext context, Future<void> Function() action, String successMessage) async {
    try {
      // 1. فقط قم باستدعاء الدالة.
      await action();

      // 2. إذا وصل الكود إلى هنا، فهذا يعني أن الدالة لم ترمِ استثناءً (نجحت).
      //    الآن تحقق فقط من أن الويدجت لا تزال موجودة قبل عرض SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت العملية بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        // يمكنك إضافة أي إجراء آخر بعد النجاح هنا (مثل العودة للشاشة السابقة)
        // Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      // إذا حدث خطأ، سيتم الانتقال إلى هنا تلقائياً.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } on ApiException catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الشركات المعلقة'),
      ),
      body: Consumer<AdminCompanyRequestsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.companyRequests.isEmpty) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.companyRequests.isEmpty) {
            return const Center(child: Text('لا توجد طلبات معلقة حالياً.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchCompanyRequests(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.companyRequests.length,
              itemBuilder: (context, index) {
                final company = provider.companyRequests[index];
                return _buildRequestCard(company, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Company company, AdminCompanyRequestsProvider provider) {
    final bool isProcessing = provider.isProcessing(company.companyId!);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name ?? 'اسم غير معروف', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline, 'مقدم الطلب:', '${company.user?.firstName ?? ''} ${company.user?.lastName ?? ''}'),
            _buildInfoRow(Icons.email_outlined, 'البريد:', company.email ?? 'لا يوجد'),
            _buildInfoRow(Icons.phone_outlined, 'الهاتف:', company.phone ?? 'لا يوجد'),

            const Divider(height: 24),

            Text('الوصف:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(company.description ?? 'لا يوجد وصف.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700)),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isProcessing)
                  const SizedBox(width: 24, height: 24, child: RiveLoadingIndicator(size: 24)) // Replaced here
                else ...[
                  TextButton(
                    onPressed: () => _handleRequest(
                        context,
                            () => provider.rejectRequest(context, company.companyId!),
                        'تم رفض الطلب بنجاح'
                    ),
                    child: const Text('رفض', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleRequest(
                        context,
                        // --- هنا تم الإصلاح ---
                            () => provider.approveRequest(context, company.companyId!),
                        'تمت الموافقة على الطلب بنجاح'
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('موافقة'),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800))),
        ],
      ),
    );
  }
}