// lib/screens/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'users/admin_users_list_screen.dart';
import 'companies/admin_companies_list_screen.dart';
import 'companies/admin_company_requests_screen.dart';
// ... قم باستيراد باقي شاشات الإدارة هنا عندما تنشئها

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
      ),
      body: GridView.count(
        crossAxisCount: 2, // عمودان في الشبكة
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildDashboardCard(
            context,
            title: 'إدارة المستخدمين',
            icon: Icons.people_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsersListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة الشركات',
            icon: Icons.business_outlined,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCompaniesListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'طلبات الشركات',
            icon: Icons.pending_actions_outlined,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCompanyRequestsScreen()));
            },
            color: Colors.orange, // لون مميز للطلبات
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة الوظائف',
            icon: Icons.work_outline,
            onTap: () {
              // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminJobsListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة الدورات',
            icon: Icons.school_outlined,
            onTap: () {
              // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCoursesListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة المقالات',
            icon: Icons.article_outlined,
            onTap: () {
              // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminArticlesListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة المهارات',
            icon: Icons.star_outline,
            onTap: () {
              // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSkillsListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة المجموعات',
            icon: Icons.group_work_outlined,
            onTap: () {
              // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminGroupsListScreen()));
            },
          ),
        ],
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