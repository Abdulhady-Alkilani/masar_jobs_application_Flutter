// lib/screens/consultant/widgets/consultant_nav_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../user_profile_screen.dart';
import '../articles/managed_articles_list_screen.dart';
import '../courses/managed_courses_list_screen.dart';

class ConsultantNavDrawer extends StatelessWidget {
  const ConsultantNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? '...'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.firstName?.substring(0, 1) ?? 'C',
                style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('ملفي الشخصي'),
            onTap: () {
              Navigator.pop(context); // إغلاق الشريط الجانبي أولاً
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('إدارة المحتوى', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('مقالاتي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedArticlesListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('دوراتي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedCoursesListScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج'),
            onTap: () {
              Navigator.pop(context);
              authProvider.logout();
            },
          ),
        ],
      ),
    );
  }
}