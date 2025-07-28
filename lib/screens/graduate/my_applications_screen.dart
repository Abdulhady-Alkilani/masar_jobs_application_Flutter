// lib/screens/graduate/my_applications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/my_applications_provider.dart';
import '../../models/job_application.dart';
import '../../services/api_service.dart';
import '../widgets/empty_state_widget.dart'; // استيراد ويدجت الحالة الفارغة
import '../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});
  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyApplicationsProvider>(context, listen: false).fetchMyApplications(context);
    });
  }

  Future<void> _deleteApplication(int applicationId, MyApplicationsProvider provider) async {
    try {
      await provider.deleteApplication(context, applicationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم سحب الطلب بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل سحب الطلب: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي للتوظيف')),
      body: Consumer<MyApplicationsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.applications.isEmpty) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (provider.error != null) {
            return EmptyStateWidget(
              icon: Icons.wifi_off_rounded,
              title: 'خطأ في الاتصال',
              message: 'لم نتمكن من جلب طلباتك. يرجى المحاولة مرة أخرى.',
              onRefresh: () => provider.fetchMyApplications(context),
            );
          }
          if (provider.applications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.inbox_rounded,
              title: 'لا توجد طلبات بعد',
              message: 'استكشف فرص العمل المتاحة في الصفحة الرئيسية وقدم على ما يناسبك!',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMyApplications(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.applications.length,
              itemBuilder: (context, index) {
                final application = provider.applications[index];
                return _buildApplicationCard(application, provider)
                    .animate(delay: (100 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.3, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(JobApplication application, MyApplicationsProvider provider) {
    final theme = Theme.of(context);
    // ... تصميم ال��طاقة هنا يمكن أن يكون مثل JobCard الذي صممناه
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              application.jobOpportunity?.jobTitle ?? 'وظيفة غير معروفة',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              application.jobOpportunity?.user?.firstName ?? 'شركة غير معروفة',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(application.status ?? 'غير معروف', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                ),
                TextButton(
                  onPressed: () => _deleteApplication(application.id!, provider),
                  child: Text('سحب الطلب', style: TextStyle(color: theme.colorScheme.error)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}