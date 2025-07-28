// lib/screens/manager/job_applicants_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/job_applicants_provider.dart';
import '../../models/applicant.dart';
import '../../services/api_service.dart';
import '../../widgets/rive_loading_indicator.dart';

class JobApplicantsScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // استخدام Provider لجلب المتقدمين لهذه الوظيفة
      Provider.of<JobApplicantsProvider>(context, listen: false).fetchApplicants(context, widget.jobId);
    });
  }

  // تابع لتغيير حالة المتقدم
  Future<void> _updateStatus(Applicant applicant, String newStatus) async {
    final provider = Provider.of<JobApplicantsProvider>(context, listen: false);
    try {
      await provider.updateApplicantStatus(context, applicant.id!, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم تحديث حالة المتقدم بنجاح'),
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
        title: Text('المتقدمون لوظيفة: ${widget.jobTitle}'),
      ),
      body: Consumer<JobApplicantsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.applicants.isEmpty) {
            return const Center(child: Text('لا يوجد متقدمون لهذه الوظيفة بعد.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchApplicants(context, widget.jobId),
            child: ListView.builder(
              itemCount: provider.applicants.length,
              itemBuilder: (context, index) {
                final applicant = provider.applicants[index];
                return _buildApplicantTile(applicant);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicantTile(Applicant applicant) {
    // التحقق من وجود بيانات المستخدم
    final user = applicant.user;
    if (user == null) {
      return const ListTile(title: Text('بيانات المتقدم غير مكتملة'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          // backgroundImage: user.photo != null ? NetworkImage(...) : null,
          child: Text(user.firstName?.substring(0, 1) ?? 'A'),
        ),
        title: Text('${user.firstName} ${user.lastName}'),
        subtitle: Text('تاريخ التقديم: ${applicant.date != null ? DateFormat('yyyy-MM-dd').format(applicant.date!) : 'غير معروف'}'),
        trailing: DropdownButton<String>(
          value: applicant.status,
          hint: const Text('الحالة'),
          underline: Container(), // لإخفاء الخط
          items: ['Pending', 'Reviewed', 'Accepted', 'Rejected']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != applicant.status) {
              _updateStatus(applicant, newValue);
            }
          },
        ),
        onTap: () {
          // عرض تفاصيل أكثر عن المتقدم في BottomSheet
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildApplicantDetailsSheet(applicant),
          );
        },
      ),
    );
  }

  Widget _buildApplicantDetailsSheet(Applicant applicant) {
    final user = applicant.user;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Text('تفاصيل المتقدم', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          if (user != null) ...[
            Text('${user.firstName} ${user.lastName}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(user.email ?? 'لا يوجد بريد إلكتروني'),
            Text(user.phone ?? 'لا يوجد هاتف'),
          ],
          const SizedBox(height: 16),
          const Text('رسالة التغطية:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(applicant.description ?? 'لا يوجد'),
          const SizedBox(height: 16),
          if (applicant.cv != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('تحميل السيرة الذاتية (CV)'),
              onPressed: () {
                // TODO: إضافة منطق لفتح رابط السيرة الذاتية
                // final url = 'BASE_URL' + applicant.cv!;
                // launchUrl(Uri.parse(url));
              },
            )
        ],
      ),
    );
  }
}