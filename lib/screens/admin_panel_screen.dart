import 'package:flutter/material.dart';
// استيراد شاشات إدارة الموارد المختلفة
import 'admin_users_list_screen.dart'; // تأكد من المسار
import 'admin_skills_list_screen.dart'; // تأكد من المسار
import 'admin_groups_list_screen.dart'; // تأكد من المسار
import 'admin_companies_list_screen.dart'; // تأكد من المسار
import 'admin_articles_list_screen.dart'; // تأكد من المسار
import 'admin_jobs_list_screen.dart'; // تأكد من المسار
import 'admin_courses_list_screen.dart'; // تأكد من المسار
import 'admin_company_requests_screen.dart'; // تأكد من المسار


class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('إدارة المستخدمين والموارد:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('إدارة المستخدمين'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsersListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('إدارة المهارات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSkillsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('إدارة المجموعات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminGroupsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('إدارة الشركات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCompaniesListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('إدارة المقالات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminArticlesListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('إدارة فرص العمل'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminJobsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('إدارة الدورات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCoursesListScreen()));
            },
          ),
          const Divider(height: 32),
          const Text('الطلبات والمعلقات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.business_center_outlined),
            title: const Text('طلبات الشركات الجديدة'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCompanyRequestsScreen()));
            },
          ),
          // يمكنك إضافة المزيد من الروابط لإدارة الطلبات الأخرى أو الإحصائيات
        ],
      ),
    );
  }
}