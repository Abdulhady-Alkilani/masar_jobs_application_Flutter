// lib/screens/consultant/consultant_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'articles/managed_articles_list_screen.dart';
import 'courses/managed_courses_list_screen.dart'; // سننشئها لاحقاً
import '../user_profile_screen.dart'; // لاستخدامها في ملفي الشخصي

class ConsultantDashboardScreen extends StatelessWidget {
  const ConsultantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الخبير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك، ${user?.firstName ?? 'خبيرنا'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'من هنا يمكنك إدارة المحتوى الخاص بك بسهولة.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const Divider(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'إدارة مقالاتي',
                    icon: Icons.article_outlined,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedArticlesListScreen()));
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'إدارة دوراتي',
                    icon: Icons.school_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedCoursesListScreen()));
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'ملفي الشخصي',
                    icon: Icons.person_outline,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50.0, color: color),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}