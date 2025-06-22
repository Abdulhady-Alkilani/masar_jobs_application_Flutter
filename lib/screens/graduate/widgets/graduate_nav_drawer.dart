// lib/screens/graduate/widgets/graduate_nav_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/auth_provider.dart';

// استيراد الشاشات
import '../../public/public_groups_screen.dart';
import '../../user_profile_screen.dart';
import '../my_applications_screen.dart';
import '../my_enrollments_screen.dart';
import '../recommendations_screen.dart';

class GraduateNavDrawer extends StatelessWidget {
  const GraduateNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    // قائمة العناصر
    final menuItems = [
      {'icon': Icons.person_search_outlined, 'title': 'ملفي الشخصي', 'screen': const UserProfileScreen()},
      {'icon': Icons.work_history_outlined, 'title': 'طلباتي للتوظيف', 'screen': const MyApplicationsScreen()},
      {'icon': Icons.school_outlined, 'title': 'دوراتي المسجلة', 'screen': const MyEnrollmentsScreen()},
      {'icon': Icons.recommend_outlined, 'title': 'توصيات لك', 'screen': const RecommendationsScreen()},
      {'icon': Icons.groups_outlined, 'title': 'مجموعات مسار', 'screen': const PublicGroupsScreen()},
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75, // عرض مناسب
      backgroundColor: const Color(0xFF1E1E2C), // خلفية داكنة جداً
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. رأس القائمة
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Row(
                children: [
                  CircleAvatar(radius: 24, child: Text(user?.firstName?.substring(0, 1) ?? 'G')),
                  const SizedBox(width: 16),
                  Text(user?.firstName ?? 'المستخدم', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

            // 2. قائمة العناصر المتحركة
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return AnimatedMenuItem(
                    index: index,
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    onTap: () => _navigateTo(context, item['screen'] as Widget),
                  );
                },
              ),
            ),

            // 3. زر تسجيل الخروج
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white54),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(context);
                authProvider.logout();
              },
            ).animate(delay: (menuItems.length * 100).ms).fadeIn(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 250), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    });
  }
}


// --- الويدجت السحرية للعنصر المتحرك ---
class AnimatedMenuItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const AnimatedMenuItem({
    Key? key,
    required this.index,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<AnimatedMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Animate(
      delay: (100 * widget.index).ms,
      effects: [
        FadeEffect(duration: 500.ms, curve: Curves.easeOut),
        SlideEffect(begin: const Offset(-1, 0), duration: 500.ms, curve: Curves.easeOut),
      ],
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // تأثير العمق
            ..rotateY(_isHovered ? -0.2 : 0), // تأثير الميلان عند المرور
          alignment: Alignment.centerLeft,
          child: ListTile(
            onTap: widget.onTap,
            leading: Icon(widget.icon, color: Colors.white),
            title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}