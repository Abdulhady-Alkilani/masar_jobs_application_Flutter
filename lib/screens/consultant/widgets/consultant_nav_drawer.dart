// lib/screens/consultant/widgets/consultant_nav_drawer.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/user.dart';

// استيراد الشاشات
import '../../manager/managed_courses_list_screen.dart';
import '../../user_profile_screen.dart';
import '../articles/managed_articles_list_screen.dart';

class ConsultantNavDrawer extends StatelessWidget {
  const ConsultantNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final theme = Theme.of(context);

    final drawerItems = [
      {'icon': Icons.person_search_outlined, 'title': 'ملفي الشخصي', 'route': () => const UserProfileScreen()},
      {'icon': Icons.edit_note_rounded, 'title': 'مقالاتي', 'route': () => const ManagedArticlesListScreen()},
      {'icon': Icons.video_library_outlined, 'title': 'دوراتي', 'route': () => const ManagedCoursesListScreen()},
    ];

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent, // مهم جداً لجعل الخلفية شفافة
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)), // حواف دائرية من جهة واحدة
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // لون زجاجي شبه شفاف
              color: theme.primaryColor.withOpacity(0.1),
              // حدود مضيئة
              border: Border(left: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5))),
            ),
            child: Stack(
              children: [
                // --- 1. خلفية الشفق القطبي المتحركة ---
                _buildAuroraBackground(theme),

                // --- 2. المحتوى ---
                Column(
                  children: [
                    _buildDrawerHeader(user, theme),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: drawerItems.map((item) {
                          return MenuItem(
                            icon: item['icon'] as IconData,
                            title: item['title'] as String,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => (item['route'] as Function)()));
                            },
                          );
                        }).toList().animate(interval: 100.ms).fadeIn(duration: 600.ms).slideX(begin: 0.5),
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
                      ),
                    ),
                  ],
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
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: CircleAvatar(
              radius: 37,
              backgroundColor: theme.primaryColor,
              child: Text(
                user?.firstName?.substring(0, 1).toUpperCase() ?? 'C',
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

  Widget _buildAuroraBackground(ThemeData theme) {
    return Stack(
      children: [
        Positioned(left: -100, top: -100, child: _buildGlow(theme.colorScheme.secondary, 400)),
        Positioned(right: -150, bottom: -150, child: _buildGlow(theme.primaryColor, 500)),
      ],
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
      duration: 20.seconds,
      begin: const Offset(1, 1),
      end: const Offset(1.5, 1.5),
      curve: Curves.easeInOut,
    )
        .then(delay: 5.seconds)
        .blur(begin: const Offset(50, 50), end: const Offset(80, 80));
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