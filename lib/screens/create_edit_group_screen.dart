import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_group_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../models/group.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// import '../models/api_exception.dart'; // تأكد من استيراد ApiException


class CreateEditGroupScreen extends StatefulWidget {
  final Group? group; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const CreateEditGroupScreen({Key? key, this.group}) : super(key: key);

  @override
  _CreateEditGroupScreenState createState() => _CreateEditGroupScreenState();
}

class _CreateEditGroupScreenState extends State<CreateEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _telegramLinkController = TextEditingController();
  // TODO: إضافة حقول التحكم للنصوص الأخرى إذا كان موديل Group يحتوي على حقول إضافية (مثل الاسم، الوصف)


  bool get isEditing => widget.group != null; // للتحقق بسهولة إذا كانت شاشة تعديل

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقول بالبيانات الحالية للمجموعة
    if (isEditing) {
      _telegramLinkController.text = widget.group!.telegramHyperLink ?? '';
      // TODO: تعبئة حقول النصوص الأخرى هنا إذا وجدت
    }
  }

  // تابع لحفظ (إنشاء أو تعديل) المجموعة
  Future<void> _saveGroup() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminGroupProvider>(context, listen: false);

      final groupData = {
        'Telegram Hyper Link': _telegramLinkController.text,
        // TODO: إضافة قيم حقول النصوص الأخرى هنا
      };

      try {
        if (isEditing) {
          // عملية تعديل
          if (widget.group!.groupId == null) {
            throw Exception('معرف المجموعة غير متوفر للتعديل.');
          }
          await provider.updateGroup(context, widget.group!.groupId!, _telegramLinkController.text); // تأكد أن تابع updateGroup يقبل string أو map حسب API
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المجموعة بنجاح.')),
          );
        } else {
          // عملية إنشاء
          await provider.createGroup(context, _telegramLinkController.text); // تأكد أن تابع createGroup يقبل string أو map
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المجموعة بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى الشاشة السابقة
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية
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
    _telegramLinkController.dispose();
    // TODO: dispose حقول النصوص الأخرى
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من AdminGroupProvider عند الحفظ
    final provider = Provider.of<AdminGroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل مجموعة' : 'إضافة مجموعة جديدة'),
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
              // حقل رابط تيليجرام
              TextFormField(
                controller: _telegramLinkController,
                decoration: const InputDecoration(labelText: 'رابط تيليجرام'),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رابط تيليجرام';
                  }
                  // TODO: يمكن إضافة تحقق لتنسيق URL صحيح هنا
                  return null;
                },
              ),
              // TODO: إضافة حقول النصوص الأخرى هنا إذا وجدت (مثل الاسم، الوصف)

              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveGroup, // تعطيل الزر أثناء التحميل
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء المجموعة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}