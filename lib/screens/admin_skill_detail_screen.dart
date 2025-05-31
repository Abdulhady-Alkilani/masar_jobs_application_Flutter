import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_skill_provider.dart'; // لجلب وتحديث وحذف
import '../models/skill.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// استيراد شاشة التعديل
import 'create_edit_skill_screen.dart'; // <--- تأكد من المسار


class AdminSkillDetailScreen extends StatefulWidget {
  final int skillId; // معرف المهارة

  const AdminSkillDetailScreen({Key? key, required this.skillId}) : super(key: key);

  @override
  _AdminSkillDetailScreenState createState() => _AdminSkillDetailScreenState();
}

class _AdminSkillDetailScreenState extends State<AdminSkillDetailScreen> {
  Skill? _skill;
  String? _skillError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSkill(); // جلب تفاصيل المهارة عند التهيئة
  }

  // تابع لجلب تفاصيل المهارة
  Future<void> _fetchSkill() async {
    setState(() { _isLoading = true; _skillError = null; });
    final adminSkillProvider = Provider.of<AdminSkillProvider>(context, listen: false);

    try {
      // TODO: إضافة تابع fetchSingleSkill(BuildContext context, int skillId) إلى AdminSkillProvider و ApiService
      // For now, simulate fetching from the list or show error if not found
      Skill? fetchedSkill = adminSkillProvider.skills.firstWhereOrNull((s) => s.skillId == widget.skillId);

      if (fetchedSkill != null) {
        setState(() {
          _skill = fetchedSkill;
          _skillError = null;
        });
      } else {
        // Fallback: حاول جلب القائمة مرة أخرى
        await adminSkillProvider.fetchAllSkills(context);
        fetchedSkill = adminSkillProvider.skills.firstWhereOrNull((s) => s.skillId == widget.skillId);

        if (fetchedSkill != null) {
          setState(() { _skill = fetchedSkill; _skillError = null; });
        } else {
          setState(() { _skill = null; _skillError = 'المهارة بمعرف ${widget.skillId} غير موجودة.'; });
        }
        // TODO: الأفضل هو استخدام تابع fetchSingleSkill من AdminSkillProvider
      }

      setState(() { _isLoading = false; });

    } on ApiException catch (e) {
      setState(() {
        _skill = null;
        _skillError = 'فشل جلب تفاصيل المهارة: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _skill = null;
        _skillError = 'فشل جلب تفاصيل المهارة: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // تابع لحذف المهارة
  Future<void> _deleteSkill() async {
    if (_skill?.skillId == null) return; // لا يمكن الحذف بدون معرف

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف المهارة "${_skill!.name ?? 'بدون اسم'}"؟'),
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; _skillError = null; }); // بداية التحميل
      final provider = Provider.of<AdminSkillProvider>(context, listen: false);
      try {
        await provider.deleteSkill(context, _skill!.skillId!); // استدعاء تابع الحذف
        // بعد النجاح، العودة إلى شاشة قائمة المهارات
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المهارة بنجاح.')),
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
          SnackBar(content: Text('فشل حذف المهارة: ${e.toString()}')),
        );
      } finally {
        setState(() { _isLoading = false; }); // انتهاء التحميل
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إلا لحالة التحميل عند عمليات الحذف/التعديل
    // final adminSkillProvider = Provider.of<AdminSkillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_skill?.name ?? 'تفاصيل المهارة'),
        actions: [
          if (_skill != null) ...[ // عرض الأزرار فقط إذا تم جلب المهارة بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : () { // تعطيل الزر أثناء التحميل
                // الانتقال إلى شاشة تعديل مهارة
                print('Edit Skill Tapped for ID ${widget.skillId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditSkillScreen(skill: _skill!), // <--- تمرير كائن المهارة للشاشة الجديدة
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteSkill, // تعطيل الزر أثناء التحميل
            ),
          ],
        ],
      ),
      body: _isLoading && _skill == null // حالة التحميل الأولية فقط
          ? const Center(child: CircularProgressIndicator())
          : _skillError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: ${_skillError!}'))
          : _skill == null // بيانات غير موجودة بعد التحميل (وإذا لا يوجد خطأ، هذا يعني 404 من API)
          ? const Center(child: Text('المهارة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المهارة
            Text('معرف المهارة: ${_skill!.skillId ?? 'غير متوفر'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('اسم المهارة: ${_skill!.name ?? 'بدون اسم'}', style: const TextStyle(fontSize: 16)),
            // يمكن إضافة المزيد من التفاصيل إذا كان موديل Skill يحتوي عليها

          ],
        ),
      ),
    );
  }
}