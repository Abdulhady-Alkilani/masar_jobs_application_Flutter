// lib/screens/admin/companies/admin_company_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_company_requests_provider.dart';
import '../../../models/company.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات إنشاء الشركات'),
      ),
      body: Consumer<AdminCompanyRequestsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.companyRequests.isEmpty) {
            return const Center(child: Text('لا توجد طلبات معلقة حالياً.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchCompanyRequests(context),
            child: ListView.builder(
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
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name ?? 'اسم غير معروف', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('مقدم الطلب: ${company.user?.firstName ?? ''} ${company.user?.lastName ?? ''}'),
            Text('البريد الإلكتروني: ${company.email ?? ''}'),
            const Divider(),
            Text(company.description ?? 'لا يوجد وصف.'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await provider.rejectRequest(context, company.companyId!);
                  },
                  child: const Text('رفض', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await provider.approveRequest(context, company.companyId!);
                  },
                  child: const Text('موافقة'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}