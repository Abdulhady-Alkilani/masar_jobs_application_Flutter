// lib/screens/public/course_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/training_course.dart';
import '../../services/api_service.dart'; // For baseUrlStorage

class CourseDetailScreen extends StatelessWidget {
  final TrainingCourse course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.courseName ?? 'تفاصيل الدورة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseName ?? 'اسم الدورة غير متوفر',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'المدرب: ${course.trainersName ?? 'غير معروف'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, Icons.description, 'الوصف', course.courseDescription),
            _buildDetailRow(context, Icons.category, 'المستوى', course.stage),
            _buildDetailRow(context, Icons.calendar_today, 'تاريخ البدء', course.startDate?.toLocal().toIso8601String().split('T')[0]),
            _buildDetailRow(context, Icons.calendar_month, 'تاريخ الانتهاء', course.endDate?.toLocal().toIso8601String().split('T')[0]),
            _buildDetailRow(context, Icons.link, 'رابط التسجيل', course.enrollHyperLink),
            // Add more details as needed
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
