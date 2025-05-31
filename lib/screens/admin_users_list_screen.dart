import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart';
import '../models/user.dart';
import 'admin_user_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة مستخدم جديد


class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({Key? key}) : super(key: key);

  @override
  _AdminUsersListScreenState createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<AdminUserProvider>(context, listen: false).fetchAllUsers(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<AdminUserProvider>(context, listen: false).fetchMoreUsers(context);
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
    final userProvider = Provider.of<AdminUserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة مستخدم جديد (CreateUserScreen)
              print('Add User Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة مستخدم لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: userProvider.isLoading && userProvider.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : userProvider.error != null
          ? Center(child: Text('Error: ${userProvider.error}'))
          : userProvider.users.isEmpty
          ? const Center(child: Text('لا يوجد مستخدمون.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: userProvider.users.length + (userProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == userProvider.users.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userProvider.users[index];
          return ListTile(
            title: Text('${user.firstName ?? ''} ${user.lastName ?? ''} (${user.username ?? ''})'),
            subtitle: Text('${user.type ?? ''} - ${user.status ?? ''}'),
            onTap: () {
              // الانتقال لتفاصيل المستخدم
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserDetailScreen(userId: user.userId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateUserScreen لإضافة مستخدم (تحتاج AdminUserProvider.createUser)