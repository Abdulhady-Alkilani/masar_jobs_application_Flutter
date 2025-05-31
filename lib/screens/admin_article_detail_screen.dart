import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_article_provider.dart'; // نحتاجها فقط إذا أردنا تحديث/حذف من هنا
import '../providers/public_article_provider.dart'; // لجلب تفاصيل المقال (إذا كان التابع العام يجلبه بالكامل)
import '../models/article.dart';
import '../services/api_service.dart';
import 'create_edit_article_screen.dart';

class AdminArticleDetailScreen extends StatefulWidget {
  final int articleId; // معرف المقال الذي سنعرض تفاصيله

  const AdminArticleDetailScreen({Key? key, required this.articleId}) : super(key: key);

  @override
  _AdminArticleDetailScreenState createState() => _AdminArticleDetailScreenState();
}

class _AdminArticleDetailScreenState extends State<AdminArticleDetailScreen> {
  Article? _article; // لتخزين بيانات المقال الفردية
  String? _articleError; // لتخزين خطأ جلب المقال
  bool _isLoading = false; // حالة تحميل خاصة بهذه الشاشة

  @override
  void initState() {
    super.initState();
    _fetchArticle(); // جلب تفاصيل المقال عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل المقال المحدد
  Future<void> _fetchArticle() async {
    setState(() { _isLoading = true; _articleError = null; });
    // هنا نستخدم تابع fetchArticle من PublicArticleProvider لأنه يجلب مقالاً واحداً بمعرفه
    // إذا أردت تابعاً خاصاً بالأدمن في AdminArticleProvider يجلبه مع علاقات إضافية مثلاً، يمكنك استخدامه بدلاً من ذلك.
    final articleProvider = Provider.of<PublicArticleProvider>(context, listen: false); // أو AdminArticleProvider إذا كان لديه fetchSingle

    try {
      final fetchedArticle = await articleProvider.fetchArticle(widget.articleId);
      setState(() {
        _article = fetchedArticle;
        _articleError = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _article = null;
        _articleError = e.message;
      });
    } catch (e) {
      setState(() {
        _article = null;
        _articleError = 'فشل جلب تفاصيل المقال: ${e.toString()}';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // TODO: تابع لحذف المقال (يستدعي AdminArticleProvider.deleteArticle) مع تأكيد
  // TODO: تابع لتعديل المقال (ينتقل لشاشة تعديل CreateEditArticleScreen)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_article?.title ?? 'تفاصيل المقال'),
        actions: [
          if (_article != null) ...[ // عرض الأزرار فقط إذا تم جلب المقال بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: الانتقال إلى شاشة تعديل المقال (CreateEditArticleScreen)
                print('Edit Article Tapped for ID ${widget.articleId}');
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditArticleScreen(article: _article))); // مرر المقال الحالي
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('وظيفة تعديل المقال لم تنفذ.')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: تابع لحذف المقال (AdminArticleProvider.deleteArticle) مع تأكيد
                print('Delete Article Tapped for ID ${widget.articleId}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('وظيفة حذف مقال لم تنفذ.')),
                );
              },
            ),
          ],
        ],
      ),
      body: _isLoading // حالة التحميل الخاصة بالشاشة
          ? const Center(child: CircularProgressIndicator())
          : _articleError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: $_articleError'))
          : _article == null // بيانات غير موجودة بعد التحميل
          ? const Center(child: Text('المقال غير موجود.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المقال (مشابه لشاشة التفاصيل العامة)
            Text(
              _article!.title ?? 'بدون عنوان',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('المؤلف UserID: ${_article!.userId ?? 'غير محدد'}', style: const TextStyle(fontSize: 16)), // عرض UserID المؤلف (خاص بالأدمن)
            Text(
              'النوع: ${_article!.type ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'تاريخ النشر: ${_article!.date?.toString().split(' ')[0] ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            // عرض الصورة
            if (_article!.articlePhoto != null && _article!.articlePhoto!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Image.network(
                  'http://127.0.0.1:8000${_article!.articlePhoto!}', // تأكد من URL الصحيح
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _article!.description ?? 'لا يوجد وصف متاح.',
              style: const TextStyle(fontSize: 16),
            ),
            // يمكنك إضافة المزيد من التفاصيل هنا (مثل created_at, updated_at)
          ],
        ),
      ),
    );
  }
}