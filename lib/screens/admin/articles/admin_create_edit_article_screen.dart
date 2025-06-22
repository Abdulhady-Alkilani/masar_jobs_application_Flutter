// lib/screens/admin/articles/admin_create_edit_article_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ستحتاج لـ intl لتنسيق التاريخ، ومكتبة لاختيار التاريخ
import 'package:intl/intl.dart';
// import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'; // مثال لمكتبة اختيار التاريخ

import '../../../models/article.dart';
import '../../../providers/admin_article_provider.dart';
import '../../../services/api_service.dart'; // لاستخدام ApiException

class AdminCreateEditArticleScreen extends StatefulWidget {
  final Article? article; // إذا كانت غير null، فنحن في وضع التعديل

  const AdminCreateEditArticleScreen({super.key, this.article});

  @override
  State<AdminCreateEditArticleScreen> createState() => _AdminCreateEditArticleScreenState();
}

class _AdminCreateEditArticleScreenState extends State<AdminCreateEditArticleScreen> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للنموذج للتحقق من صحة الحقول
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController(); // للتحكم في حقل التاريخ كـ String
  final _typeController = TextEditingController();
  final _photoController = TextEditingController(); // لمسار الصورة (إذا كان string)

  DateTime? _selectedDate; // لتخزين كائن التاريخ المختار

  bool _isSaving = false; // حالة لحفظ البيانات

  @override
  void initState() {
    super.initState();
    // إذا كنا في وضع التعديل، قم بتهيئة حقول النموذج ببيانات المقال الموجودة
    if (widget.article != null) {
      _titleController.text = widget.article!.title ?? '';
      _descriptionController.text = widget.article!.description ?? '';
      _typeController.text = widget.article!.type ?? '';
      _photoController.text = widget.article!.articlePhoto ?? ''; // إذا كانت الصورة URL/Path
      _selectedDate = widget.article!.date;
      // تنسيق التاريخ المختار للعرض في حقل النص
      if (_selectedDate != null) {
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!); // استخدم التنسيق المناسب
      }
    }
  }

  @override
  void dispose() {
    // تنظيف الـ controllers عند التخلص من الشاشة
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _typeController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  // تابع لاختيار التاريخ باستخدام DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), // ابدأ من التاريخ الحالي أو التاريخ المختار سابقاً
      firstDate: DateTime(2000), // أقرب تاريخ مسموح به
      lastDate: DateTime(2030), // أبعد تاريخ مسموح به
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!); // عرض التاريخ المختار
      });
    }
  }


  // تابع حفظ البيانات (إنشاء أو تعديل)
  Future<void> _saveArticle(BuildContext context) async {
    // تحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return; // إذا كان النموذج غير صحيح، توقف
    }

    // قم بتعيين حالة الحفظ وإعلام المستمعين
    setState(() {
      _isSaving = true;
    });

    // جمع البيانات من حقول النموذج
    final articleData = {
      // لا ترسل ArticleID في الـ body لعملية الإنشاء أو التعديل
      // الـ API يتعرف عليه من المسار في حالة التعديل
      'Title': _titleController.text,
      'Description': _descriptionController.text,
      'Type': _typeController.text,
      'Article Photo': _photoController.text, // أو التعامل مع تحميل ملف الصورة فعلياً
      'Date': _selectedDate?.toIso8601String(), // إرسال التاريخ بصيغة ISO 8601
      // 'UserID': ... // قد تحتاج لتعيين UserID إذا كان الأدمن يمكن أن يغير الكاتب
    };

    try {
      // الوصول إلى Provider لاستدعاء تابع الإنشاء أو التعديل
      final provider = Provider.of<AdminArticleProvider>(context, listen: false);

      if (widget.article == null) {
        // وضع الإنشاء
        await provider.createArticle(context, articleData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المقال بنجاح!')),
        );
      } else {
        // وضع التعديل
        await provider.updateArticle(context, widget.article!.articleId!, articleData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المقال بنجاح!')),
        );
      }

      // العودة إلى الشاشة السابقة (قائمة المقالات) بعد النجاح
      Navigator.of(context).pop();

    } on ApiException catch (e) {
      // التعامل مع أخطاء API (مثل أخطاء التحقق)
      String errorMessage = e.message;
      // إذا كان هناك أخطاء تحقق تفصيلية، يمكنك عرضها
      if (e.errors != null) {
        errorMessage += '\n' + e.errors!.entries.map((entry) => '${entry.key}: ${entry.value.join(', ')}').join('\n');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $errorMessage')),
      );
      print('API Save Error: ${e.toString()}');

    } catch (e) {
      // التعامل مع الأخطاء العامة الأخرى
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: ${e.toString()}')),
      );
      print('Unexpected Save Error: ${e.toString()}');
    } finally {
      // قم بإيقاف حالة الحفظ وإعلام المستمعين
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null; // للتحقق مما إذا كنا في وضع التعديل
    final titleText = isEditing ? 'تعديل المقال' : 'إضافة مقال جديد';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          // زر الحفظ
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator(color: Colors.white) // عرض مؤشر تحميل عند الحفظ
                : const Icon(Icons.save),
            tooltip: 'حفظ',
            onPressed: _isSaving ? null : () => _saveArticle(context), // تعطيل الزر أثناء الحفظ
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // ربط المفتاح بالنموذج
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حقل العنوان
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان المقال'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان المقال';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل الوصف/المحتوى
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'محتوى المقال'),
                maxLines: 10, // السماح بإدخال عدة أسطر
                minLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال محتوى المقال';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل نوع المقال
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'نوع المقال (مثل: نصائح، أخبار)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال نوع المقال';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل تاريخ النشر (مع زر لاختيار التاريخ)
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'تاريخ النشر',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context), // استدعاء تابع اختيار التاريخ
                  ),
                ),
                readOnly: true, // جعل الحقل غير قابل للكتابة اليدوية
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار تاريخ النشر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل مسار الصورة (إذا كان API يتعامل معه كـ String URL/Path)
              // إذا كنت تخطط لرفع صور، ستحتاج تغيير هذا لاستخدام ImagePicker
              TextFormField(
                controller: _photoController,
                decoration: const InputDecoration(labelText: 'مسار صورة المقال (URL/Path)'),
                // validator اختياري حسب ما إذا كانت الصورة إلزامية
              ),
              const SizedBox(height: 16),

              // TODO: قد تحتاج حقل UserID إذا كان الأدمن يمكن أن يختار كاتب المقال من قائمة المستخدمين
              // TextFormField(
              //   decoration: InputDecoration(labelText: 'معرف الكاتب (UserID)'),
              //   keyboardType: TextInputType.number,
              //   // ... controller و validator
              // ),
              // const SizedBox(height: 16),

              // أي حقول إضافية إذا كانت موجودة في الموديل وتريد إدارتها

              // الزر لحفظ البيانات (مكرر في الـ AppBar، يمكن إزالته هنا أو إبقاءه)
              // ElevatedButton(
              //   onPressed: _isSaving ? null : () => _saveArticle(context),
              //   child: _isSaving ? const CircularProgressIndicator() : Text(isEditing ? 'تحديث' : 'إضافة'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}