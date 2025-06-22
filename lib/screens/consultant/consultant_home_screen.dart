// lib/screens/consultant/consultant_home_screen.dart

import 'package:flutter/material.dart';
import '../public/public_articles_view.dart';
import '../public/public_job_opportunities_screen.dart';
import '../public/public_training_courses_screen.dart';
import 'widgets/consultant_nav_drawer.dart';
// استيراد الشاشات التي ستعرض المحتوى العام


class ConsultantHomeScreen extends StatefulWidget {
  const ConsultantHomeScreen({super.key});

  @override
  State<ConsultantHomeScreen> createState() => _ConsultantHomeScreenState();
}

class _ConsultantHomeScreenState extends State<ConsultantHomeScreen> {
  int _selectedIndex = 0; // للتحكم في الشريط السفلي

  // قائمة الصفحات التي سيعرضها الجسم الرئيسي
  static const List<Widget> _widgetOptions = <Widget>[
    PublicArticlesView(), // عرض المقالات العامة
    PublicJobOpportunitiesScreen(),     // عرض الوظائف العامة
    PublicTrainingCoursesScreen(),  // عرض الدورات العامة
  ];

  // قائمة بعناوين الصفحات
  static const List<String> _appBarTitles = [
    'المقالات والأخبار',
    'فرص العمل والتدريب',
    'الدورات المتاحة',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        // أيقونة فتح الشريط الجانبي ستظهر تلقائياً
      ),
      drawer: const ConsultantNavDrawer(), // <-- هنا نستخدم الشريط الجانبي
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'المقالات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'الوظائف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'الدورات',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}