import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_group_provider.dart'; // تأكد من المسار
import '../models/group.dart'; // تأكد من المسار
// يمكنك استيراد شاشة إضافة/تعديل مجموعة هنا

class AdminGroupsListScreen extends StatefulWidget {
  const AdminGroupsListScreen({Key? key}) : super(key: key);

  @override
  _AdminGroupsListScreenState createState() => _AdminGroupsListScreenState();
}

class _AdminGroupsListScreenState extends State<AdminGroupsListScreen> {
  @override
  void initState() {
    super.initState();
    // جلب قائمة المجموعات عند تهيئة الشاشة
    Provider.of<AdminGroupProvider>(context, listen: false).fetchAllGroups(context);
  }

  // تابع لحذف مجموعة (مع تأكيد)
  Future<void> _deleteGroup(int groupId) async {
    final provider = Provider.of<AdminGroupProvider>(context, listen: false);
    try {
      // TODO: أضف AlertDialog للتأكيد قبل الحذف
      await provider.deleteGroup(context, groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المجموعة بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف المجموعة: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final groupProvider = Provider.of<AdminGroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المجموعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة مجموعة جديدة (CreateEditGroupScreen)
              print('Add Group Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة مجموعة لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupProvider.error != null
          ? Center(child: Text('Error: ${groupProvider.error}'))
          : groupProvider.groups.isEmpty
          ? const Center(child: Text('لا توجد مجموعات متاحة.'))
          : ListView.builder(
        itemCount: groupProvider.groups.length,
        itemBuilder: (context, index) {
          final group = groupProvider.groups[index];
          return ListTile(
              title: Text(group.telegramHyperLink ?? 'رابط غير معروف'),
              leading: const Icon(Icons.link),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'تعديل',
                    onPressed: () {
                      // TODO: الانتقال إلى شاشة تعديل مجموعة (CreateEditGroupScreen) مع تمرير بيانات المجموعة
                      print('Edit Group Tapped for ID ${group.groupId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('وظيفة تعديل مجموعة لم تنفذ.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: () {
                      if (group.groupId != null) {
                        _deleteGroup(group.groupId!);
                      }
                    },
                  ),
                ],
              ),
              // يمكنك إضافة onTap لعرض تفاصيل إذا كان هناك شاشة تفاصيل مجموعة (لا يوجد مسار Show في api.php لمجموعات الأدمن)
              onTap: () {
                // TODO: إذا كان هناك شاشة تفاصيل مجموعة للأدمن
                print('Group Tapped: ${group.groupId}');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => AdminGroupDetailScreen(groupId: group.groupId!)));
              }
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateEditGroupScreen لإضافة أو تعديل مجموعة (تحتاج AdminGroupProvider.createGroup و .updateGroup)
// TODO: أنشئ شاشة AdminGroupDetailScreen إذا لزم الأمر لعرض تفاصيل مجموعة (تحتاج AdminGroupProvider.fetchGroup إذا أضفت التابع للـ Provider)