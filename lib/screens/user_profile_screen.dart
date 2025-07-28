// lib/screens/profile/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masar_jobs/screens/widgets/neumorphic_card.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../models/skill.dart'; // استيراد موديل المهارة
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    const backgroundColor = Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.primaryColor,
        actions: [
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
                        if (user.profile != null)
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
                        if (user.profile != null)
                          _buildInfoSection(
                            context,
                            title: 'النبذة التعريفية',
                            icon: Icons.description_outlined,
                            children: [
                              Text(
                                user.profile?.personalDescription != null &&
                                        user.profile!.personalDescription!.isNotEmpty
                                    ? user.profile!.personalDescription!
                                    : 'لا توجد نبذة تعريفية.',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[700], height: 1.5),
                              )
                            ],
                          ),
                        const SizedBox(height: 24),
                        if (user.skills != null && user.skills!.isNotEmpty)
                          _buildSkillsSection(context, user.skills!),
                      ].animate(interval: 100.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),
                    ),
                  ),
                ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User user, ThemeData theme) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          NeumorphicCard(
            isCircle: true,
            padding: const EdgeInsets.all(20),
            child: Text(
              user.firstName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                  fontSize: 40,
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${user.firstName} ${user.lastName}',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(user.type ?? 'عضو',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context,
      {required String title, required IconData icon, required List<Widget> children}) {
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
            children: skills
                .map((skill) => Chip(
                      label: Text(skill.name ?? ''),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                      labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                    ))
                .toList(),
          )
        else
          const Text('لم تتم إضافة مهارات بعد.', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
