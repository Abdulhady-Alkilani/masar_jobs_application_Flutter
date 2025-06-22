// lib/screens/graduate/my_enrollments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
// ... استيرادات أخرى
import '../../providers/my_enrollments_provider.dart';
import '../widgets/empty_state_widget.dart';

class MyEnrollmentsScreen extends StatefulWidget {
  const MyEnrollmentsScreen({super.key});
  @override
  State<MyEnrollmentsScreen> createState() => _MyEnrollmentsScreenState();
}

class _MyEnrollmentsScreenState extends State<MyEnrollmentsScreen> {
  // ... (initState و _deleteEnrollment)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دوراتي المسجلة')),
      body: Consumer<MyEnrollmentsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
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
                // ... بناء البطاقة مع حركة
              },
            ),
          );
        },
      ),
    );
  }
}