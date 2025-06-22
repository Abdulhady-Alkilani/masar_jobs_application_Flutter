// lib/screens/public_views/public_groups_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/public_group_provider.dart';
import '../../models/group.dart';
import '../widgets/empty_state_widget.dart';

class PublicGroupsScreen extends StatefulWidget {
  const PublicGroupsScreen({super.key});
  @override
  State<PublicGroupsScreen> createState() => _PublicGroupsScreenState();
}

class _PublicGroupsScreenState extends State<PublicGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PublicGroupProvider>(context, listen: false);
      // جلب البيانات فقط إذا كانت القائمة فارغة
      if (provider.groups.isEmpty) {
        provider.fetchGroups();
      }
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح الرابط: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مجموعات مسار')),
      body: Consumer<PublicGroupProvider>(
        builder: (context, provider, child) {
          // --- الحالة 1: التحميل ---
          if (provider.isLoading && provider.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- الحالة 2: وجود خطأ ---
          if (provider.error != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'حدث خطأ',
              message: 'لم نتمكن من جلب المجموعات. يرجى المحاولة مرة أخرى.',
              onRefresh: () => provider.fetchGroups(),
            );
          }

          // --- الحالة 3: لا توجد بيانات (فارغة) ---
          if (provider.groups.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.groups_2_outlined,
              title: 'لا توجد مجموعات حالياً',
              message: 'سيتم إضافة روابط المجموعات قريباً لتكون على تواصل دائم معنا ومع المجتمع.',
            );
          }

          // --- الحالة 4: النجاح ووجود بيانات (هذا هو الجزء الذي تم إصلاحه) ---
          return RefreshIndicator(
            onRefresh: () => provider.fetchGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                return GroupCard(group: group)
                    .animate(delay: (100 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.5, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }
}

// ويدجت بطاقة المجموعة
class GroupCard extends StatelessWidget {
  final Group group;
  const GroupCard({Key? key, required this.group}) : super(key: key);

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    if (!await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن فتح الرابط')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        onTap: () {
          if (group.telegramHyperLink != null && group.telegramHyperLink!.isNotEmpty) {
            _launchUrl(group.telegramHyperLink!, context);
          }
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2AABEE), // لون تيليجرام
          child: const Icon(Icons.telegram, color: Colors.white),
        ),
        title: Text(
          'مجموعة تيليجرام ${DateTime.now().millisecond + UniqueKey().hashCode}', // عنوان فريد بسيط
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          group.telegramHyperLink ?? 'اضغط للانضمام',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.open_in_new, color: theme.primaryColor),
      ),
    );
  }
}