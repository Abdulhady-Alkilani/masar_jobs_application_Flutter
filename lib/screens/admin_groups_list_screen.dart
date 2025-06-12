import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_group_provider.dart'; // لتنفيذ عمليات CRUD
import '../models/group.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO المطلوبة
import 'admin_group_detail_screen.dart'; // شاشة التفاصيل
import 'create_edit_group_screen.dart'; // <--- شاشة إضافة/تعديل مجموعة


class AdminGroupsListScreen extends StatefulWidget {
  const AdminGroupsListScreen({Key? key}) : super(key: key);

  @override
  _AdminGroupsListScreenState createState() => _AdminGroupsListScreenState();
}

class _AdminGroupsListScreenState extends State<AdminGroupsListScreen> {
  // لا نحتاج ScrollController هنا لأن AdminGroupProvider لا يستخدم Pagination حالياً
  // إذا أضفت Pagination لاحقاً، ستحتاج إضافة ScrollController ومستمع له

  @override
  void initState() {
    super.initState();
    // جلب قائمة المجموعات عند تهيئة الشاشة
    Provider.of<AdminGroupProvider>(context, listen: false).fetchAllGroups(context);
    // إذا أضفت Pagination، ستحتاج إضافة مستمع الـ scroll هنا
  }

  @override
  void dispose() {
    // إذا أضفت ScrollController، لا تنسى dispose هنا
    super.dispose();
  }

  // تابع لحذف مجموعة
  Future<void> _deleteGroup(int groupId) async {
    // يمكن إضافة حالة تحميل خاصة هنا إذا أردت (في Stateful Widget)
    // setState(() { _isDeleting = true; }); // مثال

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه المجموعة؟'), // يمكنك عرض رابط المجموعة هنا إذا كان متاحاً بسهولة
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه
      final provider = Provider.of<AdminGroupProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteGroup(context, groupId);
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المجموعة بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف المجموعة: ${e.toString()}')),
        );
      } finally {
        // setState(() { _isDeleting = false; }); // مثال
      }
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
          // زر إضافة مجموعة جديدة
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: groupProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
              // الانتقال إلى شاشة إضافة مجموعة جديدة (CreateEditGroupScreen)
              print('Add Group Tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  // نمرر null لـ group للإشارة إلى أنها شاشة إضافة
                  builder: (context) => const CreateEditGroupScreen(group: null),
                ),
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
          // تأكد أن المجموعة لديها ID قبل عرض أزرار التعديل/الحذف أو الانتقال
          if (group.groupId == null) return const SizedBox.shrink();

          return ListTile(
              title: Text(group.telegramHyperLink ?? 'رابط غير معروف'),
              leading: const Icon(Icons.link), // أيقونة للمجموعة
              trailing: Row( // أزرار التعديل والحذف في نفس الصف
                mainAxisSize: MainAxisSize.min, // لجعل Row تأخذ فقط المساحة اللازمة لأزرارها
                children: [
                  // زر تعديل مجموعة
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'تعديل',
                    onPressed: groupProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                      // الانتقال إلى شاشة تعديل مجموعة
                      print('Edit Group Tapped for ID ${group.groupId}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // نمرر كائن المجموعة لـ CreateEditGroupScreen للإشارة إلى أنها شاشة تعديل
                          builder: (context) => CreateEditGroupScreen(group: group),
                        ),
                      );
                    },
                  ),
                  // زر حذف مجموعة
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: groupProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                      _deleteGroup(group.groupId!); // استدعاء تابع الحذف
                    },
                  ),
                ],
              ),
              // onTap لعرض تفاصيل مجموعة (AdminGroupDetailScreen)
              onTap: groupProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
                print('Group Tapped: ${group.groupId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminGroupDetailScreen(groupId: group.groupId!), // <--- الانتقال لشاشة التفاصيل
                  ),
                );
              }
          );
        },
      ),
    );
  }
}

// Simple extension for List<Group> if not available elsewhere or using collection package
extension ListAdminGroupExtension on List<Group> {
  Group? firstWhereOrNull(bool Function(Group) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}