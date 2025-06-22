// lib/screens/admin/users/admin_users_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_user_provider.dart';
import '../../../../models/user.dart';
import 'admin_create_edit_user_screen.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AdminUserProvider>(context, listen: false);

    // جلب الصفحة الأولى
    provider.fetchAllUsers(context);

    // إضافة مستمع للتمرير لجلب المزيد من البيانات
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreUsers(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إضافة مستخدم جديد',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminCreateEditUserScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminUserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.users.isEmpty) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllUsers(context),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.users.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.users.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = provider.users[index];
                return _buildUserTile(user, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserTile(User user, AdminUserProvider provider) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.firstName?.substring(0, 1) ?? 'U'),
      ),
      title: Text('${user.firstName} ${user.lastName}'),
      subtitle: Text('${user.email} - (${user.type})'),
      trailing: IconButton(
        icon: const Icon(Icons.edit_note, color: Colors.blue),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminCreateEditUserScreen(user: user)),
          );
        },
      ),
      // يمكنك إضافة onTap لعرض تفاصيل أكثر أو قائمة منسدلة للحذف
    );
  }
}