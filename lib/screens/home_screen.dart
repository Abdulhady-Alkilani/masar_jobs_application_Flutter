// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masar_jobs/screens/public/public_articles_view.dart';
import 'package:masar_jobs/screens/public/public_job_opportunities_screen.dart';
import 'package:masar_jobs/screens/public/public_training_courses_screen.dart';
import 'package:provider/provider.dart';
import 'graduate/widgets/graduate_nav_drawer.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final AnimationController _bgController;

  // تعريف ألوان الخلفيات لكل قسم
  final List<List<Color>> _backgroundColors = [
    [const Color(0xFF005AA7), const Color(0xFFFFFDE4)], // أزرق وأبيض للوظائف
    [const Color(0xFF6a3093), const Color(0xFFa044ff)], // بنفسجي للدورات
    [const Color(0xFFf857a6), const Color(0xFFff5858)], // برتقالي-وردي للمقالات
  ];

  // اللون الحالي
  late ColorTween _colorTween;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: 600.ms);
    _colorTween = ColorTween(begin: _backgroundColors[0][0], end: _backgroundColors[0][1]);
    _bgController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // تحديث ألوان الخلفية
    _colorTween = ColorTween(
        begin: _backgroundColors[_selectedIndex][0],
        end: _backgroundColors[index][0]);

    _bgController.reset();
    _bgController.forward();

    setState(() { _selectedIndex = index; });
    _pageController.animateToPage(
      index,
      duration: 400.ms,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(['الوظائف', 'الدورات', 'المقالات'][_selectedIndex],
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: const GraduateNavDrawer(), // استخدم الشريط الجانبي الأنيق
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _colorTween.transform(_bgController.value)!,
                  _backgroundColors[_selectedIndex][1]
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: _onItemTapped,
          children: const [
            PublicJobOpportunitiesScreen(),
            PublicTrainingCoursesScreen(),
            PublicArticlesView(),
          ],
        ),
      ),
      bottomNavigationBar: _buildLiquidBottomNav(),
    );
  }

  // شريط تنقل سفلي بتصميم مميز
  Widget _buildLiquidBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          return _buildNavItem(
            icon: [Icons.work_outline, Icons.school_outlined, Icons.article_outlined][index],
            isSelected: _selectedIndex == index,
            onTap: () => _onItemTapped(index),
          );
        }),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.elasticOut,
        width: isSelected ? 80 : 50,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}