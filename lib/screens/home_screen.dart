import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'my_applications_screen.dart'; // تأكد من المسار
import 'my_enrollments_screen.dart'; // تأكد من المسار
import 'user_profile_screen.dart'; // تأكد من المسار
import 'recommendations_screen.dart'; // تأكد من المسار
import 'public_articles_list_screen.dart'; // تأكد من المسار
import 'public_jobs_list_screen.dart'; // تأكد من المسار
import 'public_courses_list_screen.dart'; // تأكد من المسار
import 'public_companies_list_screen.dart'; // تأكد من المسار
import 'public_groups_list_screen.dart'; // تأكد من المسار
import 'public_skills_list_screen.dart'; // تأكد من المسار
import 'managed_company_screen.dart'; // تأكد من المسار (لمدير الشركة)
import 'consultant_articles_screen.dart'; // تأكد من المسار (للاستشاري)
import 'admin_panel_screen.dart'; // تأكد من المسار (للأدمن)


class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // تحديد الشاشات المتاحة بناءً على نوع المستخدم
    List<Widget> userSpecificSections = [];
    if (user?.type == 'خريج') {
      userSpecificSections = [
        ListTile(
          leading: const Icon(Icons.work),
          title: const Text('طلبات التوظيف الخاصة بي'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyApplicationsScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.school),
          title: const Text('تسجيلات الدورات الخاصة بي'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyEnrollmentsScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.recommend),
          title: const Text('التوصيات'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendationsScreen()));
          },
        ),
      ];
    } else if (user?.type == 'مدير شركة') {
      userSpecificSections = [
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('شركتي'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedCompanyScreen()));
          },
        ),
        // شاشات إدارة الوظائف والدورات والمتقدمين للمدير ستكون من ManagedCompanyScreen أو لوحة تحكم خاصة بالمدير
      ];
    } else if (user?.type == 'خبير استشاري') {
      userSpecificSections = [
        ListTile(
          leading: const Icon(Icons.article),
          title: const Text('مقالاتي'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsultantArticlesScreen()));
          },
        ),
        // شاشات إدارة الدورات والمسجلين للاستشاري ستكون من شاشة مقالاته أو لوحة تحكم خاصة
      ];
    } else if (user?.type == 'Admin') {
      userSpecificSections = [
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('لوحة تحكم الأدمن'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
          },
        ),
      ];
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('الشاشة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Text(
              'مرحباً بك، ${user?.firstName ?? 'مستخدم'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('نوع الحساب: ${user?.type ?? 'غير معروف'}')),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('ملفي الشخصي'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
            },
          ),
          ...userSpecificSections, // إضافة الأقسام الخاصة بنوع المستخدم
          const Divider(height: 32),
          const Text('الموارد العامة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('المقالات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublicArticlesListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('فرص العمل والتدريب'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublicJobsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('الدورات التدريبية'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublicCoursesListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('الشركات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublicCompaniesListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('المجموعات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublicGroupsListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('المهارات'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PublicSkillsListScreen()));
            },
          ),
        ],
      ),
    );
  }
}