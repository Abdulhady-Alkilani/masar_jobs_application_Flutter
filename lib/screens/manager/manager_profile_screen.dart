// lib/screens/manager/manager_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'edit_manager_profile_screen.dart'; // سننشئ هذه الشاشة تالياً
import '../../widgets/rive_loading_indicator.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدم Consumer للاستماع للتغييرات بعد التحديث
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (authProvider.isLoading && user == null) {
          return const Scaffold(body: Center(child: RiveLoadingIndicator()));
        }

        if (user == null) {
          return const Scaffold(body: Center(child: Text('لا يمكن تحميل بيانات المستخدم')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('الملف الشخصي'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل الملف الشخصي',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditManagerProfileScreen(user: user),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      // backgroundImage: user.photo != null ? NetworkImage('BASE_URL' + user.photo!) : null,
                      backgroundColor: Colors.grey.shade200,
                      child: user.photo == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                          onPressed: () {
                            // نفس وظيفة زر التعديل في الأعلى
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditManagerProfileScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${user.firstName ?? ''} ${user.lastName ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  user.type ?? 'مدير شركة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', user.email ?? 'غير متوفر'),
                        const Divider(),
                        _buildInfoRow(Icons.person_outline, 'اسم المستخدم', user.username ?? 'غير متوفر'),
                        const Divider(),
                        _buildInfoRow(Icons.phone_outlined, 'رقم الهاتف', user.phone ?? 'لم يتم إضافته'),
                      ],
                    ),
                  ),
                ),
                // يمكنك إضافة معلومات الشركة هنا أيضاً إذا أردت
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}