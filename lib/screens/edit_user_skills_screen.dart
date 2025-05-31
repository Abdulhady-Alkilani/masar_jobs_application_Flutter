import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // للحصول على المستخدم الحالي والتوكن واستدعاء syncUserSkills
import '../providers/public_skill_provider.dart'; // لجلب قائمة جميع المهارات المتاحة
import '../models/user.dart';
import '../models/skill.dart';
import '../services/api_service.dart'; // لاستخدام ApiException

class EditUserSkillsScreen extends StatefulWidget {
  const EditUserSkillsScreen({Key? key}) : super(key: key);

  @override
  _EditUserSkillsScreenState createState() => _EditUserSkillsScreenState();
}

class _EditUserSkillsScreenState extends State<EditUserSkillsScreen> {
  // قائمة المهارات المختارة (ستكون Map لتخزين الـ Stage أيضاً)
  final Map<int, String?> _selectedSkills = {}; // {SkillID: Stage}

  // TODO: قائمة مستويات المهارة المتاحة (يجب أن تأتي من Backend إذا كانت قيم محددة)
  final List<String> _availableStages = ['مبتدئ', 'متوسط', 'متقدم'];

  @override
  void initState() {
    super.initState();
    // جلب قائمة جميع المهارات المتاحة
    Provider.of<PublicSkillProvider>(context, listen: false).fetchSkills();
    // جلب بيانات المستخدم الحالي مرة أخرى للتأكد من تحميل المهارات المرتبطة بالكامل
    // (أو يمكن افتراض أنها محملة في AuthProvider.user)
    // final user = Provider.of<AuthProvider>(context, listen: false).user;
    // إذا كان المستخدم موجوداً ومهاراته محملة، عبّئ الـ _selectedSkills
    final userSkills = Provider.of<AuthProvider>(context, listen: false).user?.skills;
    if (userSkills != null) {
      for (var skill in userSkills) {
        if (skill.skillId != null) {
          _selectedSkills[skill.skillId!] = skill.pivot?.stage;
        }
      }
    }
  }

  // تابع للتبديل بين اختيار المهارة وتحديد مستواها
  void _toggleSkill(int skillId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedSkills[skillId] = _availableStages.first; // تعيين مستوى افتراضي عند الاختيار
      } else {
        _selectedSkills.remove(skillId);
      }
    });
  }

  // تابع لتحديث مستوى مهارة مختارة
  void _updateSkillStage(int skillId, String? stage) {
    setState(() {
      _selectedSkills[skillId] = stage;
    });
  }

  // تابع لحفظ المهارات المحدثة
  Future<void> _saveSkills() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: المستخدم غير مصادق عليه.')),
      );
      return;
    }

    // تهيئة بيانات المهارات لإرسالها لـ API (بصيغة Map {SkillID: {Stage: value}})
    final skillsToSync = <String, Map<String, dynamic>>{};
    _selectedSkills.forEach((skillId, stage) {
      skillsToSync[skillId.toString()] = {'Stage': stage};
    });

    try {
      ApiService apiService = new ApiService();
      // استدعاء تابع مزامنة المهارات في AuthProvider
       await apiService.syncUserSkills(authProvider.token!, skillsToSync);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المهارات بنجاح.')),
      );
      // بعد النجاح، العودة إلى شاشة الملف الشخصي
      Navigator.pop(context);

    } on ApiException catch (e) {
      String errorMessage = 'فشل التحديث: ${e.message}';
      if (e.errors != null) {
        errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        print(e.errors);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لـ PublicSkillProvider لجلب قائمة جميع المهارات المتاحة
    final skillProvider = Provider.of<PublicSkillProvider>(context);
    // الاستماع لـ AuthProvider لحالة التحميل عند حفظ المهارات
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المهارات'),
      ),
      body: skillProvider.isLoading // حالة تحميل قائمة المهارات المتاحة
          ? const Center(child: CircularProgressIndicator())
          : skillProvider.error != null // خطأ في جلب المهارات المتاحة
          ? Center(child: Text('Error loading skills: ${skillProvider.error}'))
          : Column( // استخدام Column لوضع زر الحفظ في الأسفل
        children: [
          // قائمة المهارات للاختيار وتحديد المستوى
          Expanded( // لجعل القائمة تأخذ المساحة المتبقية
            child: ListView.builder(
              itemCount: skillProvider.skills.length,
              itemBuilder: (context, index) {
                final skill = skillProvider.skills[index];
                final bool isSelected = _selectedSkills.containsKey(skill.skillId);

                return ListTile(
                  title: Text(skill.name ?? 'مهارة غير معروفة'),
                  leading: Checkbox( // مربع اختيار لاختيار المهارة
                    value: isSelected,
                    onChanged: (bool? newValue) {
                      if (skill.skillId != null && newValue != null) {
                        _toggleSkill(skill.skillId!, newValue);
                      }
                    },
                  ),
                  trailing: isSelected // عرض قائمة تحديد المستوى فقط إذا كانت المهارة مختارة
                      ? DropdownButton<String>(
                    value: _selectedSkills[skill.skillId], // القيمة الحالية للمستوى
                    items: _availableStages.map((String stage) {
                      return DropdownMenuItem<String>(
                        value: stage,
                        child: Text(stage),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (skill.skillId != null) {
                        _updateSkillStage(skill.skillId!, newValue);
                      }
                    },
                    hint: const Text('المستوى'), // نص توضيحي إذا لم يتم اختيار مستوى
                  )
                      : null, // لا شيء إذا لم تكن المهارة مختارة
                );
              },
            ),
          ),
          // زر الحفظ في الأسفل
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: authProvider.isLoading || _selectedSkills.isEmpty // تعطيل الزر أثناء التحميل أو إذا لم يتم اختيار أي مهارات
                  ? null
                  : _saveSkills,
              child: const Text('حفظ المهارات'),
            ),
          ),
        ],
      ),
    );
  }
}