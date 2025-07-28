import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../user_profile_screen.dart';
import '../my_applications_screen.dart';

class ModernDrawer extends StatefulWidget {
  const ModernDrawer({super.key});

  @override
  State<ModernDrawer> createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                color: theme.primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.firstName?.substring(0, 1) ?? 'U',
                        style: TextStyle(fontSize: 28, color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.firstName ?? 'المستخدم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "خريج",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 16),
                  children: [
                    _buildMenuItem(
                      context,
                      index: 0,
                      icon: Icons.home_outlined,
                      title: "الصفحة الرئيسية",
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildMenuItem(
                      context,
                      index: 1,
                      icon: Icons.work_outline,
                      title: "طلباتي للتوظيف",
                      onTap: () => _navigateTo(context, const MyApplicationsScreen()),
                    ),
                    _buildMenuItem(
                      context,
                      index: 2,
                      icon: Icons.school_outlined,
                      title: "دوراتي المسجلة",
                      onTap: () {
                        // TODO: Navigate to My Enrollments Screen
                      },
                    ),
                    _buildMenuItem(
                      context,
                      index: 3,
                      icon: Icons.lightbulb_outline,
                      title: "توصيات لك",
                      onTap: () {
                        // TODO: Navigate to Recommendations Screen
                      },
                    ),
                    _buildMenuItem(
                      context,
                      index: 4,
                      icon: Icons.person_outline,
                      title: "ملفي الشخصي",
                      onTap: () => _navigateTo(context, const UserProfileScreen()),
                    ),
                  ],
                ),
              ),

              // Logout Button
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  authProvider.logout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? theme.primaryColor : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? theme.primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          onTap();
        },
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer first
    // Use a slight delay to avoid jank while the drawer is closing
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }
}
