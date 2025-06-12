import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_article_provider.dart'; // نحتاجها لتنفيذ التعديل/الحذف
import '../providers/public_article_provider.dart'; // لجلب تفاصيل المقال (إذا كان التابع العام يجلبه بالكامل)
import '../models/article.dart';
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشة التعديل
import 'create_edit_article_screen.dart'; // <--- تأكد من المسار (شاشة تعديل مقال الأدمن)


class AdminArticleDetailScreen extends StatefulWidget {
  final int articleId; // معرف المقال الذي سنعرض تفاصيله

  const AdminArticleDetailScreen({Key? key, required this.articleId}) : super(key: key);

  @override
  _AdminArticleDetailScreenState createState() => _AdminArticleDetailScreenState();
}

class _AdminArticleDetailScreenState extends State<AdminArticleDetailScreen> {
  Article? _article; // لتخزين بيانات المقال الفردية
  String? _articleError; // لتخزين خطأ جلب المقال
  bool _isLoadingInitialData = false; // حالة تحميل خاصة بالشاشة لجلب البيانات الأولية
  bool _isDeleting = false; // حالة تحميل خاصة بعملية الحذف


  @override
  void initState() {
    super.initState();
    _fetchArticle(); // جلب تفاصيل المقال عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل المقال المحدد
  Future<void> _fetchArticle() async {
    setState(() { _isLoadingInitialData = true; _articleError = null; });
    // هنا نستخدم تابع جلب مقال واحد من Provider (يفترض وجوده)
    final adminArticleProvider = Provider.of<AdminArticleProvider>(context, listen: false);


    try {
      // TODO: إضافة تابع fetchSingleArticle(BuildContext context, int articleId) إلى AdminArticleProvider و ApiService
      // For now, simulate fetching from the list or show error if not found
      // هذا الجزء يعتمد على أن AdminArticleProvider.fetchAllArticles قد حمل القائمة بالفعل
      // وهو ليس الأسلوب الأمثل لصفحة تفاصيل
      final article = await adminArticleProvider.fetchSingleArticle(context, widget.articleId);


      setState(() {
        _article = article;
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
      setState(() { _isLoadingInitialData = false; });
    }
  }

  // تابع لحذف المقال
  Future<void> _deleteArticle() async {
    // لا يمكن الحذف بدون معرف أو إذا كان يتم الحذف بالفعل
    if (_article?.articleId == null || _isDeleting) return;


    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>( // عرض مربع حوار تأكيد
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف المقال "${_article!.title ?? 'بدون عنوان'}"؟'),
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      setState(() { _isDeleting = true; _articleError = null; }); // بداية التحميل للحذف
      final provider = Provider.of<AdminArticleProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteArticle(context, _article!.articleId!);

        // بعد النجاح، العودة إلى شاشة قائمة المقالات
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المقال بنجاح.')),
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
          SnackBar(content: Text('فشل حذف المقال: ${e.toString()}')),
        );
      } finally {
        setState(() { _isDeleting = false; }); // انتهاء التحميل للحذف
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إلا لحالة التحميل العامة أو حالة الخطأ العامة
    // final adminProvider = Provider.of<AdminArticleProvider>(context);


    return Scaffold(
      appBar: AppBar(
        title: Text(_article?.title ?? 'تفاصيل المقال'),
        actions: [
          if (_article != null) ...[ // عرض الأزرار فقط إذا تم جلب المقال بنجاح
            // زر التعديل
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isDeleting || _isLoadingInitialData ? null : () { // تعطيل الزر أثناء أي تحميل
                // الانتقال إلى شاشة تعديل المقال
                print('Edit Article Tapped for ID ${widget.articleId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditArticleScreen(article: _article), // <--- تمرير كائن المقال للشاشة الجديدة
                  ),
                );
              },
            ),
            // زر الحذف
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isDeleting || _isLoadingInitialData ? null : _deleteArticle, // تعطيل الزر أثناء أي تحميل
            ),
          ],
        ],
      ),
      // عرض مؤشر تحميل أثناء جلب البيانات الأولية أو أثناء الحذف
      body: _isLoadingInitialData || _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : _articleError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: ${_articleError!}'))
          : _article == null // بيانات غير موجودة بعد التحميل (وإذا لا يوجد خطأ، هذا يعني 404 من API)
          ? const Center(child: Text('المقال غير موجود.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المقال
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
            const Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _article!.description ?? 'لا يوجد وصف متاح.',
              style: const TextStyle(fontSize: 16),
            ),
            // يمكن إضافة المزيد من التفاصيل
          ],
        ),
      ),
    );
  }
}

// Simple extension for List<Article> if not available elsewhere or using collection package
extension ListArticleExtension on List<Article> {
  Article? firstWhereOrNull(bool Function(Article) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}