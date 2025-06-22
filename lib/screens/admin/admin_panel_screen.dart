// lib/screens/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:masar_jobs/screens/admin/skills/admin_skills_list_screen.dart';
import 'package:provider/provider.dart'; // استيراد Provider
import '../../providers/auth_provider.dart'; // استيراد AuthProvider

import 'articles/admin_articles_list_screen.dart';
import 'courses/admin_courses_list_screen.dart';
import 'groups/admin_groups_list_screen.dart';
import 'jobs/admin_jobs_list_screen.dart';
import 'users/admin_users_list_screen.dart';
import 'companies/admin_companies_list_screen.dart';
import 'companies/admin_company_requests_screen.dart';
// ... قم باستيراد باقي شاشات الإدارة هنا عندما تنشئها
// import 'articles/admin_articles_list_screen.dart'; // مثال لاستيراد شاشة المقالات

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        actions: [
          // إضافة زر تسجيل الخروج في قائمة الإجراءات (actions)
          IconButton(
            icon: const Icon(Icons.logout), // أيقونة تسجيل الخروج
            tooltip: 'تسجيل الخروج', // نص يظهر عند التمرير فوق الزر
            onPressed: () async {
              // استدعاء تابع تسجيل الخروج من AuthProvider
              // listen: false لأننا فقط نستدعي تابع ولا نستمع للتغييرات
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              // بعد تسجيل الخروج، يجب أن يقوم التطبيق بالانتقال إلى شاشة تسجيل الدخول
              // وهذا عادةً يتم التعامل معه في مستوى أعلى (مثل MyApp أو MainScreen)
              // بالاستماع لتغييرات حالة المصادقة في AuthProvider.
            },
          ),
        ],
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminJobsListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة الدورات',
            icon: Icons.school_outlined,
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCoursesListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة المقالات',
            icon: Icons.article_outlined,
            onTap: () {
              // مثال للانتقال إذا كانت الشاشة جاهزة
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminArticlesListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة المهارات',
            icon: Icons.star_outline,
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSkillsListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: 'إدارة المجموعات',
            icon: Icons.group_work_outlined,
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminGroupsListScreen()));
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