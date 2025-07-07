// lib/screens/graduate/my_enrollments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/my_enrollments_provider.dart';
import '../../models/enrollment.dart';
import '../../services/api_service.dart';
import '../widgets/empty_state_widget.dart';

class MyEnrollmentsScreen extends StatefulWidget {
  const MyEnrollmentsScreen({super.key});

  @override
  State<MyEnrollmentsScreen> createState() => _MyEnrollmentsScreenState();
}

class _MyEnrollmentsScreenState extends State<MyEnrollmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyEnrollmentsProvider>(context, listen: false).fetchMyEnrollments(context);
    });
  }

  Future<void> _deleteEnrollment(int enrollmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء التسجيل'),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء تسجيلك في هذه الدورة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('نعم، ألغِ التسجيل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<MyEnrollmentsProvider>(context, listen: false).deleteEnrollment(context, enrollmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء التسجيل بنجاح'), backgroundColor: Colors.green),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الإلغاء: ${e.message}'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('دوراتي المسجلة'),
      ),
      body: Consumer<MyEnrollmentsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.enrollments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'حدث خطأ',
              message: 'تعذر جلب الدورات المسجلة. حاول تحديث الصفحة.',
              onRefresh: () => provider.fetchMyEnrollments(context),
            );
          }
          if (provider.enrollments.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.school_outlined,
              title: 'ابدأ رحلتك التعليمية',
              message: 'لم تسجل في أي دورات بعد. تصفح قسم الدورات وابدأ بتطوير مهاراتك اليوم!',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMyEnrollments(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.enrollments.length,
              itemBuilder: (context, index) {
                final enrollment = provider.enrollments[index];
                // --- بناء البطاقة مع حركة ---
                return EnrollmentCard(
                  enrollment: enrollment,
                  onDelete: () => _deleteEnrollment(enrollment.enrollmentId!),
                ).animate(delay: (100 * (index % 10)).ms).fadeIn(duration: 500.ms).slideY(begin: 0.2);
              },
            ),
          );
        },
      ),
    );
  }
}

// --- ويدجت البطاقة المخصصة ---
class EnrollmentCard extends StatelessWidget {
  final Enrollment enrollment;
  final VoidCallback onDelete;

  const EnrollmentCard({
    Key? key,
    required this.enrollment,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = enrollment.trainingCourse;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (enrollment.status?.toLowerCase()) {
      case 'مكتمل':
        statusColor = Colors.green;
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'قيد التقدم':
      default: // الحالة الافتراضية هي قيد التقدم
        statusColor = theme.primaryColor;
        statusText = 'قيد التقدم';
        statusIcon = Icons.timelapse_outlined;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course != null) ...[
              Text(
                course.courseName ?? 'دورة غير معروفة',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'المدرب: ${course.trainersName ?? 'غير معروف'}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: Icon(statusIcon, color: statusColor, size: 18),
                  label: Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                  backgroundColor: statusColor.withOpacity(0.1),
                  side: BorderSide.none,
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  label: const Text('إلغاء التسجيل', style: TextStyle(color: Colors.red, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )
              ],
            ),
            if (enrollment.date != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'تاريخ التسجيل: ${DateFormat('dd MMMM yyyy', 'ar').format(enrollment.date!)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}