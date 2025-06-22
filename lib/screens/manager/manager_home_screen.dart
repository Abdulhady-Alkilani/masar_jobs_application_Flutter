// lib/screens/manager/manager_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/managed_company_provider.dart';
import 'create_company_request_screen.dart';
import 'managed_company_dashboard_screen.dart';
import 'managed_courses_list_screen.dart';
import 'managed_jobs_list_screen.dart';
import 'manager_profile_screen.dart';


class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ManagedCompanyDashboardScreen(),
    ManagedJobsListScreen(),
    ManagedCoursesListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // لعرض العناوين المناسبة في AppBar
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'إدارة الوظائف';
      case 2:
        return 'إدارة الدورات';
      default:
        return 'مدير الشركة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex)),
        elevation: 1,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('${user?.firstName ?? ''} ${user?.lastName ?? ''}'),
              accountEmail: Text(user?.email ?? 'لا يوجد بريد إلكتروني'),
              currentAccountPicture: CircleAvatar(
                // يمكنك استخدام NetworkImage هنا إذا كان لديك رابط لصورة المستخدم
                // backgroundImage: user?.photo != null ? NetworkImage('BASE_URL' + user!.photo!) : null,
                backgroundColor: Colors.white,
                child: Text(
                  user?.firstName?.substring(0, 1) ?? 'U',
                  style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('الملف الشخصي'),
              onTap: () {
                Navigator.pop(context); // أغلق الشريط الجانبي أولاً
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagerProfileScreen()));
              },
            ),
            // هذا الجزء يعرض "شركتي" أو "إنشاء شركة" بناءً على الحالة
            Consumer<ManagedCompanyProvider>(
              builder: (context, companyProvider, child) {
                // تأكد من جلب البيانات عند الحاجة
                if (companyProvider.company == null && !companyProvider.isLoading) {
                  // يمكنك استدعاء الجلب هنا ولكن الأفضل أن يتم في الشاشة نفسها
                }

                if (companyProvider.hasCompany) {
                  return ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('شركتي'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() { _selectedIndex = 0; }); // انتقل للوحة التحكم
                    },
                  );
                } else {
                  return ListTile(
                    leading: const Icon(Icons.add_business_outlined),
                    title: const Text('طلب إنشاء شركة'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCompanyRequestScreen()));
                    },
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
                // WrapperScreen سيتعامل مع إعادة التوجيه
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'التحكم',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'الوظائف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'الدورات',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}