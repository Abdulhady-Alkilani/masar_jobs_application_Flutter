import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masar_jobs/providers/theme_provider.dart';
import 'package:masar_jobs/screens/graduate/gemini_chat_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: 400.ms,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // Align title to start
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Row(
          children: [
            Image.asset(
              'assets/image/app_logo.png', // TODO: Replace with actual app logo
              height: 40, // Adjust height as needed
            ),
            const SizedBox(width: 16),
            Text(
              ['الوظائف', 'الدورات', 'المقالات'][_selectedIndex],
              style: TextStyle(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              );
            },
          ),
        ],
      ),
      drawer: const GraduateNavDrawer(), // استخدم الشريط الجانبي الأنيق
      body: PageView(
        controller: _pageController,
        onPageChanged: _onItemTapped,
        children: const [
          PublicJobOpportunitiesScreen(),
          PublicTrainingCoursesScreen(),
          PublicArticlesView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GeminiChatScreen()),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimary),
        label: Text('Ask Gemini', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ).animate().fadeIn(delay: 500.ms).slideX(),
      bottomNavigationBar: _buildLiquidBottomNav(),
    );
  }

  // شريط تنقل سفلي بتصميم مميز
  Widget _buildLiquidBottomNav() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(20),
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          return _buildNavItem(
            icon: [
              Icons.work_outline,
              Icons.school_outlined,
              Icons.article_outlined
            ][index],
            isSelected: _selectedIndex == index,
            onTap: () => _onItemTapped(index),
          );
        }),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.elasticOut,
        width: isSelected ? 80 : 50,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(icon,
            color: isSelected
                ? theme.colorScheme.onSecondary
                : theme.colorScheme.onSurface),
      ),
    );
  }
}