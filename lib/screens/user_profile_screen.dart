// lib/screens/profile/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../models/skill.dart'; // استيراد موديل المهارة
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدم watch للاستماع للتغيرات وإعادة بناء الواجهة
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    // تعريف لون الخلفية ليتناسب مع تصميم Neumorphism
    const backgroundColor = Color(0xFFE3F2FD); // سماوي فاتح جداً (أفتح من السابق)

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.primaryColor,
        actions: [
          // زر التعديل الوحيد في الشريط العلوي
          if (user != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(userToEdit: user)),
                );
              },
              tooltip: 'تعديل الملف الشخصي',
            ),
        ],
      ),
      body: authProvider.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? const Center(child: Text('تعذر تحميل بيانات المستخدم.'))
          : RefreshIndicator(
        onRefresh: () => Provider.of<AuthProvider>(context, listen: false).checkAuthStatus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserHeader(context, user, theme),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                title: 'المعلومات الأساسية',
                icon: Icons.badge_outlined,
                children: [
                  _buildInfoRow('البريد الإلكتروني', user.email ?? '...'),
                  _buildInfoRow('رقم الهاتف', user.phone ?? 'لم يضف'),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                title: 'المعلومات الأكاديمية',
                icon: Icons.school_outlined,
                children: [
                  _buildInfoRow('الجامعة', user.profile?.university ?? 'لم تضف'),
                  _buildInfoRow('المعدل التراكمي', user.profile?.gpa ?? 'لم يضف'),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                title: 'النبذة التعريفية',
                icon: Icons.description_outlined,
                children: [
                  Text(
                    user.profile?.personalDescription != null && user.profile!.personalDescription!.isNotEmpty
                        ? user.profile!.personalDescription!
                        : 'لا توجد نبذة تعريفية.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.5),
                  )
                ],
              ),
              const SizedBox(height: 24),
              _buildSkillsSection(context, user.skills ?? []),
            ].animate(interval: 100.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),
          ),
        ),
      ),
    );
  }

  // --- دوال مساعدة لجعل الكود أنظف ---

  Widget _buildUserHeader(BuildContext context, User user, ThemeData theme) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(user.type ?? 'عضو', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          NeumorphicButton(
            isCircle: true,
            padding: const EdgeInsets.all(20),
            child: Text(
              user.firstName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(fontSize: 28, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return NeumorphicCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context, List<Skill> skills) {
    return _buildInfoSection(
      context,
      title: 'المهارات',
      icon: Icons.star_outline,
      children: [
        if (skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => Chip(
              label: Text(skill.name ?? ''),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              side: BorderSide.none,
              labelStyle: TextStyle(color: Theme.of(context).primaryColor),
            )).toList(),
          )
        else
          const Text('لم تتم إضافة مهارات بعد.', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// --- ويدجت Neumorphic (يمكن نقلها إلى ملف منفصل في widgets/) ---
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const NeumorphicCard({Key? key, required this.child, this.padding = const EdgeInsets.all(20)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(5, 5), blurRadius: 10),
          const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isCircle;
  final EdgeInsets padding;
  const NeumorphicButton({Key? key, required this.child, this.onTap, this.isCircle = false, this.padding = const EdgeInsets.all(12)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(padding: padding, child: child),
    );
  }
}