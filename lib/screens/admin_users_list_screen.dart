import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart';
import '../models/user.dart';
import 'admin_user_detail_screen.dart';
// استيراد شاشة إضافة مستخدم جديد
import 'create_user_screen.dart'; // <--- تأكد من المسار


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
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !Provider.of<AdminUserProvider>(context, listen: false).isFetchingMore &&
          Provider.of<AdminUserProvider>(context, listen: false).hasMorePages) {
        Provider.of<AdminUserProvider>(context, listen: false).fetchMoreUsers(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // لا يوجد تابع حذف مستخدم هنا، يتم الحذف من شاشة التفاصيل


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<AdminUserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          // زر إضافة مستخدم جديد
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: userProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
              // الانتقال إلى شاشة إضافة مستخدم جديد (CreateUserScreen)
              print('Add User Tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateUserScreen(), // <--- الانتقال لشاشة الإضافة
                ),
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
          // عرض عنصر التحميل في النهاية
          if (index == userProvider.users.length) {
            return userProvider.isFetchingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
          final user = userProvider.users[index];
          // تأكد أن المستخدم لديه ID قبل الانتقال للتفاصيل
          if (user.userId == null) return const SizedBox.shrink();

          return ListTile(
            title: Text('${user.firstName ?? ''} ${user.lastName ?? ''} (${user.username ?? ''})'),
            subtitle: Text('${user.type ?? ''} - ${user.status ?? ''}'),
            onTap: userProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
              // الانتقال لتفاصيل المستخدم
              print('User Tapped: ${user.userId}');
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

// Simple extension for List<User>
extension ListUserExtension on List<User> {
  User? firstWhereOrNull(bool Function(User) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}