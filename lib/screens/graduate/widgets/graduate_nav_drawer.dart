// lib/screens/graduate/widgets/graduate_nav_drawer.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';

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
    // هذا هو أساس التصميم
    return const _DrawerContent();
  }
}

class _DrawerContent extends StatelessWidget {
  const _DrawerContent();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final theme = Theme.of(context);

    // قائمة العناصر لتسهيل الإدارة
    final drawerItems = [
      {'icon': Icons.person_search_outlined, 'title': 'ملفي الشخصي', 'route': () => const UserProfileScreen()},
      {'icon': Icons.work_history_outlined, 'title': 'طلباتي للتوظيف', 'route': () => const MyApplicationsScreen()},
      {'icon': Icons.school_outlined, 'title': 'دوراتي المسجلة', 'route': () => const MyEnrollmentsScreen()},
      {'icon': Icons.recommend_outlined, 'title': 'توصيات لك', 'route': () => const RecommendationsScreen()},
      {'icon': Icons.groups_outlined, 'title': 'مجموعات مسار', 'route': () => const PublicGroupsScreen()},
    ];

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent, // مهم جداً لجعل الخلفية شفافة
      child: ClipRRect(
        // استخدام حواف دائرية من جهة واحدة فقط
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              // لون زجاجي شبه شفاف
              color: theme.primaryColor.withOpacity(0.15),
              // حدود مضيئة
              border: Border(left: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDrawerHeader(user, theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: drawerItems.length,
                    itemBuilder: (context, index) {
                      final item = drawerItems[index];
                      return MenuItem(
                        icon: item['icon'] as IconData,
                        title: item['title'] as String,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => (item['route'] as Function)()));
                        },
                      ).animate(delay: (100 * (index + 1)).ms).fadeIn().slideX(begin: 0.5);
                    },
                  ),
                ),
                const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MenuItem(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    isLogout: true,
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthProvider>().logout();
                    },
                  ).animate().fadeIn(delay: 800.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(User? user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: CircleAvatar(
              radius: 37,
              backgroundColor: theme.primaryColor,
              child: Text(
                user?.firstName?.substring(0, 1).toUpperCase() ?? 'G',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${user?.firstName} ${user?.lastName}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.3);
  }
}

// --- ويدجت عنصر القائمة المتوهج ---
class MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const MenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  }) : super(key: key);

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isLogout ? Colors.red.shade400 : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 250.ms,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovered ? Colors.white.withOpacity(0.15) : Colors.transparent,
            boxShadow: _isHovered ? [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ] : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}