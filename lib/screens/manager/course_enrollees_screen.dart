// lib/screens/manager/course_enrollees_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/course_enrollees_provider.dart';
import '../../models/enrollee.dart';
import '../../services/api_service.dart';
import '../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class CourseEnrolleesScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CourseEnrolleesScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseEnrolleesScreen> createState() => _CourseEnrolleesScreenState();
}

class _CourseEnrolleesScreenState extends State<CourseEnrolleesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseEnrolleesProvider>(context, listen: false).fetchEnrollees(context, widget.courseId);
    });
  }

  Future<void> _updateStatus(Enrollee enrollee, String newStatus) async {
    final provider = Provider.of<CourseEnrolleesProvider>(context, listen: false);
    try {
      await provider.updateEnrolleeStatus(context, enrollee.enrollmentId!, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم تحديث حالة المسجل بنجاح'),
        backgroundColor: Colors.green,
      ));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل تحديث الحالة: ${e.message}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المسجلون في: ${widget.courseTitle}'),
      ),
      body: Consumer<CourseEnrolleesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.enrollees.isEmpty) {
            return const Center(child: Text('لا يوجد مسجلون في هذه الدورة بعد.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchEnrollees(context, widget.courseId),
            child: ListView.builder(
              itemCount: provider.enrollees.length,
              itemBuilder: (context, index) {
                final enrollee = provider.enrollees[index];
                return _buildEnrolleeTile(enrollee);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnrolleeTile(Enrollee enrollee) {
    final user = enrollee.user;
    if (user == null) {
      return const ListTile(title: Text('بيانات المسجل غير مكتملة'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.firstName?.substring(0, 1) ?? 'E')),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Text('تاريخ التسجيل: ${enrollee.date != null ? DateFormat('yyyy-MM-dd').format(enrollee.date!) : 'غير معروف'}'),
        trailing: DropdownButton<String>(
          value: enrollee.status,
          hint: const Text('الحالة'),
          underline: Container(),
          items: ['قيد التقدم', 'مكتمل', 'ملغي']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != enrollee.status) {
              _updateStatus(enrollee, newValue);
            }
          },
        ),
      ),
    );
  }
}