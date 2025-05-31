import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_article_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../models/article.dart'; // تأكد من المسار
import '../models/user.dart';
import '../services/api_service.dart'; // قد تحتاج لجلب قائمة المستخدمين لربط المقال بهم (لـ Admin)
// يمكن استيراد provider للمستخدمين إذا كنت ستعرض قائمة للمؤلف

class CreateEditArticleScreen extends StatefulWidget {
  final Article? article; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const CreateEditArticleScreen({Key? key, this.article}) : super(key: key);

  @override
  _CreateEditArticleScreenState createState() => _CreateEditArticleScreenState();
}

class _CreateEditArticleScreenState extends State<CreateEditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _typeController = TextEditingController(); // أو Dropdown
  final TextEditingController _articlePhotoController = TextEditingController(); // أو أداة اختيار ملف
  TextEditingController _userIdController = TextEditingController(); // لتعيين المؤلف (لـ Admin)

  DateTime? _selectedDate; // لتخزين التاريخ المختار من منتقي التاريخ

  bool get isEditing => widget.article != null; // للتحقق بسهولة إذا كانت شاشة تعديل

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقول بالبيانات الحالية للمقال
    if (isEditing) {
      _titleController.text = widget.article!.title ?? '';
      _descriptionController.text = widget.article!.description ?? '';
      _selectedDate = widget.article!.date;
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? ''; // عرض التاريخ فقط
      _typeController.text = widget.article!.type ?? '';
      _articlePhotoController.text = widget.article!.articlePhoto ?? '';
      _userIdController.text = widget.article!.userId?.toString() ?? ''; // عرض UserID الحالي
    } else {
      // في حالة الإضافة، يمكن تعيين تاريخ النشر الافتراضي للتاريخ الحالي
      _selectedDate = DateTime.now();
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
    }

    // TODO: إذا كنت ستستخدم Dropdown لاختيار نوع المقال أو مؤلفه (UserID)، قم بجلب قائمة الخيارات هنا
    // مثل fetchUserList() أو fetchArticleTypes().
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
        _dateController.text = picked.toString().split(' ')[0]; // عرض التاريخ فقط
      });
    }
  }


  // تابع لحفظ (إنشاء أو تعديل) المقال
  Future<void> _saveArticle() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminArticleProvider>(context, listen: false);

      final articleData = {
        'UserID': int.tryParse(_userIdController.text), // تحويل النص إلى عدد صحيح
        'Title': _titleController.text,
        'Description': _descriptionController.text,
        'Date': _selectedDate?.toIso8601String().split('T')[0], // إرسال التاريخ فقط YYYY-MM-DD
        'Type': _typeController.text,
        'Article Photo': _articlePhotoController.text, // أو معالجة رفع ملف
      };

      try {
        if (isEditing) {
          // عملية تعديل
          await provider.updateArticle(context, widget.article!.articleId!, articleData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المقال بنجاح.')),
          );
        } else {
          // عملية إنشاء
          await provider.createArticle(context, articleData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المقال بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى شاشة قائمة المقالات
        Navigator.pop(context);

      } catch (e) {
        // عرض رسائل الخطأ (مثل أخطاء التحقق من API)
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.toString()}';
        if (e is ApiException && e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors); // يمكنك معالجة أخطاء التحقق بشكل أفضل وعرضها تحت الحقول المعنية
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _typeController.dispose();
    _articlePhotoController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminArticleProvider>(context); // للاستماع لحالة التحميل عند الحفظ

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل مقال' : 'إضافة مقال جديد'),
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
              // حقل User ID (لتعيين المؤلف بواسطة الأدمن)
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'معرف المؤلف (UserID)'),
                keyboardType: TextInputType.number, // يجب أن يكون رقماً
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال معرف المؤلف';
                  }
                  if (int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح لمعرف المؤلف';
                  }
                  // TODO: يمكنك إضافة تحقق هنا للتأكد من وجود UserID المدخل في قاعدة البيانات
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
                maxLines: 5, // جعل الحقل متعدد الأسطر
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
                readOnly: true, // جعل الحقل للقراءة فقط (التحكم عبر الأيقونة)
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
                onPressed: _saveArticle,
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء المقال'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO: يمكنك إضافة شاشة EditUserSkillsScreen بنفس النمط لملف المستخدم الشخصي (تحتاج لـ PublicSkillProvider لجلب المهارات المتاحة ولـ AuthProvider لـ syncUserSkills)