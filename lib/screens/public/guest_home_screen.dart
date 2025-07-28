// lib/screens/public/guest_home_screen.dart
import 'package:flutter/material.dart';
import '../public_articles_list_screen.dart';
import 'public_job_opportunities_screen.dart';
import 'public_training_courses_screen.dart';
import '../login_screen.dart';
import '../register_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const PublicJobOpportunitiesScreen(isGuest: true),
    const PublicTrainingCoursesScreen(isGuest: true),
    const PublicArticlesListScreen(isGuest: true),
  ];

  final List<String> _titles = const [
    'الوظائف المتاحة',
    'الدورات التدريبية',
    'المقالات',
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
        title: Text(_titles[_selectedIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تسجيل الدخول',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8, bottom: 8),
            child: InkWell(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                     BoxShadow(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: const Center(
                  child: Text(
                    'إنشاء حساب',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work),
                label: 'الوظائف',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'الدورات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                activeIcon: Icon(Icons.article),
                label: 'المقالات',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.7),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
