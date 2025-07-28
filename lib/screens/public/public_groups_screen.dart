// lib/screens/public_views/public_groups_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/public_group_provider.dart';
import '../../models/group.dart';
import '../widgets/empty_state_widget.dart';
import '../../widgets/rive_loading_indicator.dart';

class PublicGroupsScreen extends StatefulWidget {
  const PublicGroupsScreen({super.key});
  @override
  State<PublicGroupsScreen> createState() => _PublicGroupsScreenState();
}

class _PublicGroupsScreenState extends State<PublicGroupsScreen> {
  @override
  void initState() {
    super.initState();
    // استدعاء جلب البيانات عند بناء الويدجت لأول مرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PublicGroupProvider>(context, listen: false).fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات'),
      ),
      body: Consumer<PublicGroupProvider>(
        builder: (context, provider, child) {
          // الحالة 1: التحميل
          if (provider.isLoading && provider.groups.isEmpty) {
            return const Center(child: RiveLoadingIndicator());
          }

          // الحالة 2: وجود خطأ
          if (provider.error != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'حدث خطأ',
              message: 'لم نتمكن من جلب المجموعات. يرجى المحاولة مرة أخرى.',
              onRefresh: () => provider.fetchGroups(),
            );
          }

          // الحالة 3: لا توجد بيانات
          if (provider.groups.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.groups_2_outlined,
              title: 'لا توجد مجموعات حالياً',
              message: 'سيتم إضافة روابط المجموعات قريباً لتكون على تواصل دائم.',
            );
          }

          // الحالة 4: النجاح وعرض البيانات
          return RefreshIndicator(
            onRefresh: () => provider.fetchGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                return GroupCard(group: group, index: index + 1)
                    .animate(delay: (100 * index).ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.5, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }
}

// --- ويدجت البطاقة المخصصة للمجموعات ---
class GroupCard extends StatelessWidget {
  final Group group;
  final int index; // لاستخدامه في العنوان

  const GroupCard({Key? key, required this.group, required this.index}) : super(key: key);

  // دالة لفتح الروابط الخارجية
  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح الرابط: $urlString')),
        );
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
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFF2AABEE), // لون تيليجرام
          child: Icon(Icons.telegram, color: Colors.white, size: 32),
        ),
        title: Text(
          'مجموعة على تيليجرام #$index',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          group.telegramHyperLink ?? 'اضغط للانضمام',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr, // لضمان عرض الرابط بشكل صحيح
        ),
        trailing: Icon(Icons.open_in_new, color: theme.primaryColor),
      ),
    );
  }
}