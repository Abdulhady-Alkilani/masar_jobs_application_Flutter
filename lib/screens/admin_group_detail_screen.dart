import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_group_provider.dart'; // لجلب وتحديث وحذف
import '../models/group.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// استيراد شاشة التعديل
import 'create_edit_group_screen.dart'; // <--- تأكد من المسار


class AdminGroupDetailScreen extends StatefulWidget {
  final int groupId; // معرف المجموعة

  const AdminGroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _AdminGroupDetailScreenState createState() => _AdminGroupDetailScreenState();
}

class _AdminGroupDetailScreenState extends State<AdminGroupDetailScreen> {
  Group? _group;
  String? _groupError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGroup(); // جلب تفاصيل المجموعة عند التهيئة
  }

  // تابع لجلب تفاصيل المجموعة
  Future<void> _fetchGroup() async {
    setState(() { _isLoading = true; _groupError = null; });
    final adminGroupProvider = Provider.of<AdminGroupProvider>(context, listen: false);

    try {
      // TODO: إضافة تابع fetchSingleGroup(BuildContext context, int groupId) إلى AdminGroupProvider و ApiService
      // For now, simulate fetching from the list or show error if not found
      Group? fetchedGroup = adminGroupProvider.groups.firstWhereOrNull((g) => g.groupId == widget.groupId);

      if (fetchedGroup != null) {
        setState(() {
          _group = fetchedGroup;
          _groupError = null;
        });
      } else {
        // Fallback: حاول جلب القائمة مرة أخرى
        await adminGroupProvider.fetchAllGroups(context);
        fetchedGroup = adminGroupProvider.groups.firstWhereOrNull((g) => g.groupId == widget.groupId);

        if (fetchedGroup != null) {
          setState(() { _group = fetchedGroup; _groupError = null; });
        } else {
          setState(() { _group = null; _groupError = 'المجموعة بمعرف ${widget.groupId} غير موجودة.'; });
        }
        // TODO: الأفضل هو استخدام تابع fetchSingleGroup من AdminGroupProvider
      }

      setState(() { _isLoading = false; });

    } on ApiException catch (e) {
      setState(() {
        _group = null;
        _groupError = 'فشل جلب تفاصيل المجموعة: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _group = null;
        _groupError = 'فشل جلب تفاصيل المجموعة: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // تابع لحذف المجموعة
  Future<void> _deleteGroup() async {
    if (_group?.groupId == null) return; // لا يمكن الحذف بدون معرف

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف المجموعة التي رابطها "${_group!.telegramHyperLink ?? 'بدون رابط'}"؟'),
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; _groupError = null; }); // بداية التحميل
      final provider = Provider.of<AdminGroupProvider>(context, listen: false);
      try {
        await provider.deleteGroup(context, _group!.groupId!); // استدعاء تابع الحذف
        // بعد النجاح، العودة إلى شاشة قائمة المجموعات
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المجموعة بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف المجموعة: ${e.toString()}')),
        );
      } finally {
        setState(() { _isLoading = false; }); // انتهاء التحميل
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إلا لحالة التحميل عند عمليات الحذف/التعديل
    // final adminGroupProvider = Provider.of<AdminGroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المجموعة'),
        actions: [
          if (_group != null) ...[ // عرض الأزرار فقط إذا تم جلب المجموعة بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : () { // تعطيل الزر أثناء التحميل
                // الانتقال إلى شاشة تعديل مجموعة
                print('Edit Group Tapped for ID ${widget.groupId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditGroupScreen(group: _group!), // <--- تمرير كائن المجموعة للشاشة الجديدة
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteGroup, // تعطيل الزر أثناء التحميل
            ),
          ],
        ],
      ),
      body: _isLoading && _group == null // حالة التحميل الأولية فقط
          ? const Center(child: CircularProgressIndicator())
          : _groupError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: ${_groupError!}'))
          : _group == null // بيانات غير موجودة بعد التحميل (وإذا لا يوجد خطأ، هذا يعني 404 من API)
          ? const Center(child: Text('المجموعة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المجموعة
            Text('معرف المجموعة: ${_group!.groupId ?? 'غير متوفر'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_group!.telegramHyperLink != null) ...[
              const Text('رابط تيليجرام:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(_group!.telegramHyperLink!, style: const TextStyle(fontSize: 16)), // يمكن جعله clickable
            ],
            // يمكن إضافة المزيد من التفاصيل إذا كان موديل Group يحتوي عليها

          ],
        ),
      ),
    );
  }
}