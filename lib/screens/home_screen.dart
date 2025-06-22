// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:masar_jobs/screens/graduate/widgets/graduate_nav_drawer.dart';

// استيراد الشاشات التي ستعرض القوائم
import 'package:masar_jobs/screens/public/public_job_opportunities_screen.dart';
import 'package:masar_jobs/screens/public/public_training_courses_screen.dart';
import 'package:masar_jobs/screens/public/public_articles_view.dart';

import 'graduate/widgets/rive_animated_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pageTitles = ['فرص العمل', 'الدورات التدريبية', 'المقالات'];

    return Scaffold(
      appBar: AppBar(

        title: Text(pageTitles[_selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      drawer: const GraduateNavDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        // --- هنا التصحيح ---
        // يجب أن نضع الشاشات الكاملة هنا، وليس البطاقات
        children: const [
          PublicJobOpportunitiesScreen(),
          PublicTrainingCoursesScreen(),
          PublicArticlesView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'الوظائف'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'الدورات'),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'المقالات'),
        ],
      ),
    );
  }
}