import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_skill_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../models/skill.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
//import '../models/api_exception.dart'; // <--- تأكد من استيراد ApiException بشكل صحيح


class CreateEditSkillScreen extends StatefulWidget {
  final Skill? skill; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const CreateEditSkillScreen({Key? key, this.skill}) : super(key: key);

  @override
  _CreateEditSkillScreenState createState() => _CreateEditSkillScreenState();
}

class _CreateEditSkillScreenState extends State<CreateEditSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool get isEditing => widget.skill != null; // للتحقق بسهولة إذا كانت شاشة تعديل

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقل بالاسم الحالي للمهارة
    if (isEditing) {
      _nameController.text = widget.skill!.name ?? '';
    }
  }

  // تابع لحفظ (إنشاء أو تعديل) المهارة
  Future<void> _saveSkill() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminSkillProvider>(context, listen: false);

      final skillName = _nameController.text;

      try {
        if (isEditing) {
          // عملية تعديل
          if (widget.skill!.skillId == null) {
            throw Exception('معرف المهارة غير متوفر للتعديل.');
          }
          await provider.updateSkill(context, widget.skill!.skillId!, skillName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المهارة بنجاح.')),
          );
        } else {
          // عملية إنشاء
          await provider.createSkill(context, skillName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المهارة بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى شاشة قائمة المهارات
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب حقل الاسم
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من AdminSkillProvider عند الحفظ
    final provider = Provider.of<AdminSkillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل مهارة' : 'إضافة مهارة جديدة'),
      ),
      body: provider.isLoading // إذا كان Provider يحمل بيانات (عند الحفظ)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقل اسم المهارة
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المهارة'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المهارة';
                  }
                  // TODO: يمكنك إضافة تحقق هنا للتأكد من عدم تكرار اسم المهارة (باستثناء المهارة الحالية في حالة التعديل)
                  // هذا التحقق يتم في Backend أيضاً، لكن يمكن البدء بتحقق بسيط في الواجهة
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveSkill, // تعطيل الزر أثناء التحميل
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء المهارة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}