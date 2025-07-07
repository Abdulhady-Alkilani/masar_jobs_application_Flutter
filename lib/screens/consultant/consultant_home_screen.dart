// lib/screens/consultant/consultant_home_screen.dart

import 'package:flutter/material.dart';
import '../public/public_articles_view.dart';
import '../public/public_job_opportunities_screen.dart';
import 'widgets/consultant_nav_drawer.dart'; // استيراد الشريط الجانبي



class ConsultantHomeScreen extends StatefulWidget {
  const ConsultantHomeScreen({super.key});

  @override
  State<ConsultantHomeScreen> createState() => _ConsultantHomeScreenState();
}

class _ConsultantHomeScreenState extends State<ConsultantHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const List<Widget> _widgetOptions = <Widget>[
    PublicArticlesView(),
    PublicJobOpportunitiesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['المقالات', 'الوظائف', 'الدورات'][_selectedIndex]),
      ),
      // --- هنا نستخدم الـ Drawer بالطريقة القياسية ---
      drawer: const ConsultantNavDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'المقالات'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'الوظائف'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'الدورات'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}