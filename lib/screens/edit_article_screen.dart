import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consultant_article_provider.dart'; // للاستشاري
import '../providers/admin_article_provider.dart'; // للأدمن
import '../providers/auth_provider.dart'; // لمعرفة نوع المستخدم
import '../models/article.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
import '../models/user.dart'; // لاستخدام موديل المستخدم


class EditArticleScreen extends StatefulWidget {
  final Article article; // المقال الذي سيتم تعديله (مطلوب دائماً لهذه الشاشة)

  const EditArticleScreen({Key? key, required this.article}) : super(key: key);

  @override
  _EditArticleScreenState createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  final TextEditingController _userIdController = TextEditingController(); // للأدمن فقط: لتعيين المؤلف
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // تاريخ النشر
  final TextEditingController _typeController = TextEditingController(); // أو Dropdown
  final TextEditingController _articlePhotoController = TextEditingController(); // أو أداة اختيار ملف

  DateTime? _selectedDate; // لتخزين التاريخ المختار من منتقي التاريخ


  @override
  void initState() {
    super.initState();
    // تعبئة الحقول بالبيانات الحالية للمقال الممرر
    _userIdController.text = widget.article.userId?.toString() ?? '';
    _titleController.text = widget.article.title ?? '';
    _descriptionController.text = widget.article.description ?? '';
    _selectedDate = widget.article.date;
    _dateController.text = _selectedDate?.toString().split(' ')[0] ?? ''; // عرض التاريخ فقط
    _typeController.text = widget.article.type ?? '';
    _articlePhotoController.text = widget.article.articlePhoto ?? '';

    // TODO: إذا كنت ستستخدم Dropdown لأنواع محددة (مثل Type) أو لاختيار المؤلف (UserID) من قائمة، قم بتهيئة الخيارات وجلب قائمة المستخدمين إذا كان المستخدم أدمن
  }

  // تابع لاختيار التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }


  // تابع لحفظ التعديلات
  Future<void> _saveArticle() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // تحديد provider المناسب بناءً على نوع المستخدم الحالي
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final User? currentUser = authProvider.user;

      if (currentUser == null) {
        // هذا لا ينبغي أن يحدث إذا كانت الشاشة محمية بشكل صحيح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: بيانات المستخدم غير متوفرة.')),
        );
        return;
      }

      // بيانات المقال المراد إرسالها
      final articleData = {
        // UserID فقط للأدمن في حالة التعديل إذا تم تضمينه في البيانات، الاستشاري لا يعدل هذا
        if (currentUser.type == 'Admin' && _userIdController.text.isNotEmpty)
          'UserID': int.tryParse(_userIdController.text), // يجب أن يكون عدد صحيح
        'Title': _titleController.text,
        'Description': _descriptionController.text,
        'Date': _selectedDate?.toIso8601String().split('T')[0], // إرسال التاريخ بصيغة YYYY-MM-DD
        'Type': _typeController.text,
        'Article Photo': _articlePhotoController.text.isEmpty ? null : _articlePhotoController.text, // إرسال null إذا كان فارغاً (أو معالجة رفع ملف)
      };

      try {
        // عملية تعديل (دائماً في هذه الشاشة)
        // يجب أن يكون معرف المقال متوفراً من الكائن الممرر
        if (widget.article.articleId == null) {
          throw Exception('معرف المقال غير متوفر للتعديل.');
        }

        // استخدم provider المناسب based on user type
        if (currentUser.type == 'Admin') {
          final adminProvider = Provider.of<AdminArticleProvider>(context, listen: false);
          // تأكد من أن API يقبل UserID في PUT إذا تم تضمينه في البيانات
          await adminProvider.updateArticle(context, widget.article.articleId!, articleData);
        } else if (currentUser.type == 'خبير استشاري') {
          final consultantProvider = Provider.of<ConsultantArticleProvider>(context, listen: false);
          // الاستشاري لا يرسل UserID عند التعديل، backend يضعه تلقائياً بناءً على التوكن
          articleData.remove('UserID'); // إزالة UserID إذا كان موجوداً في البيانات
          await consultantProvider.updateArticle(context, widget.article.articleId!, articleData);
        } else {
          // نوع مستخدم غير مصرح له بالتعديل (لا ينبغي الوصول هنا)
          throw ApiException(403, 'You are not authorized to update articles.');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المقال بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة تفاصيل المقال (أو شاشة القائمة إذا كان التعديل من القائمة)
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل التحديث: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية في الفورم
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
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _typeController.dispose();
    _articlePhotoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نحتاج لمعرفة نوع المستخدم لعرض/إخفاء حقول معينة وتحديد Provider الصحيح
    final currentUser = Provider.of<AuthProvider>(context).user;

    // نستخدم Provider المناسب للاستماع لحالة التحميل عند الحفظ
    final provider = currentUser?.type == 'Admin'
        ? Provider.of<AdminArticleProvider>(context)
        : Provider.of<ConsultantArticleProvider>(context);

    // إذا لم يتم تحميل المستخدم الحالي بعد أو حدث خطأ
    if (currentUser == null) {
      return Scaffold(appBar: AppBar(title: const Text('خطأ')), body: const Center(child: Text('بيانات المستخدم غير متوفرة.')));
    }

    // تحديد ما إذا كان المستخدم الحالي هو الأدمن
    bool isAdmin = currentUser.type == 'Admin';
    // تحديد ما إذا كان المستخدم الحالي هو الاستشاري
    bool isConsultant = currentUser.type == 'خبير استشاري';

    // إذا لم يكن المستخدم لا أدمن ولا استشاري، فلا يمكنه الوصول لهذه الشاشة (افتراضاً)
    if (!isAdmin && !isConsultant) {
      return Scaffold(appBar: AppBar(title: const Text('غير مصرح')), body: const Center(child: Text('غير مصرح لك بالوصول لهذه الصفحة للتعديل.')));
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل مقال'), // دائماً شاشة تعديل
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
              // حقل User ID (خاص بالأدمن فقط)
              if (isAdmin) // عرض الحقل فقط إذا كان المستخدم أدمن
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(labelText: 'معرف المؤلف (UserID)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // إذا كان الأدمن يعدل، هذا الحقل مطلوب إذا أراد تغييره
                      return 'الرجاء إدخال معرف المؤلف';
                    }
                    if (int.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح لمعرف المؤلف';
                    }
                    // TODO: تحقق من وجود UserID (يتم التحقق في Backend أيضاً)
                    return null;
                  },
                ),
              if (isAdmin) const SizedBox(height: 12), // مسافة إذا تم عرض حقل UserID

              // حقل العنوان
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'العنوان'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال العنوان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل الوصف (يمكن جعله متعدد الأسطر)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف / نص المقال'),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوصف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل التاريخ (مع منتقي تاريخ)
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ النشر',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context), // استدعاء منتقي التاريخ
                  ),
                ),
                readOnly: true, // جعل الحقل للقراءة فقط
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار تاريخ النشر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // حقل النوع (يمكن استبداله بـ Dropdown)
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'النوع'),
                // validator: (value) { ... }, // إضافة تحقق إذا كانت هناك قيم محددة مسموح بها
              ),
              const SizedBox(height: 12),
              // حقل مسار الصورة (أو زر لاختيار ملف)
              TextFormField(
                controller: _articlePhotoController,
                decoration: const InputDecoration(labelText: 'رابط / مسار الصورة'),
                // validator: (value) { ... }, // إضافة تحقق إذا كان URL
              ),
              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveArticle, // تعطيل الزر أثناء التحميل
                child: const Text('حفظ التعديلات'), // دائماً نص حفظ التعديلات
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ChangeNotifier {
  bool get isLoading => false;
}