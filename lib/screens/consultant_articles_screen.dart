import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consultant_article_provider.dart'; // لتنفيذ عمليات CRUD
import '../models/article.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO المطلوبة
import 'consultant_article_detail_screen.dart'; // شاشة التفاصيل
import 'create_edit_article_screen.dart'; // <--- شاشة إضافة/تعديل مقال


class ConsultantArticlesScreen extends StatefulWidget {
  const ConsultantArticlesScreen({Key? key}) : super(key: key);

  @override
  _ConsultantArticlesScreenState createState() => _ConsultantArticlesScreenState();
}

class _ConsultantArticlesScreenState extends State<ConsultantArticlesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب قائمة المقالات عند تهيئة الشاشة
    Provider.of<ConsultantArticleProvider>(context, listen: false).fetchManagedArticles(context);

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق من أن هناك المزيد لتحميله ومن أننا لسنا بصدد جلب بالفعل
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !Provider.of<ConsultantArticleProvider>(context, listen: false).isFetchingMore &&
          Provider.of<ConsultantArticleProvider>(context, listen: false).hasMorePages) {
        Provider.of<ConsultantArticleProvider>(context, listen: false).fetchMoreManagedArticles(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // تابع لحذف مقال
  Future<void> _deleteArticle(int articleId) async {
    // يمكن إضافة حالة تحميل خاصة هنا إذا أردت (في Stateful Widget)
    // setState(() { _isDeleting = true; }); // مثال

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا المقال؟'), // يمكنك عرض عنوان المقال هنا
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // حالة التحميل ستتم معالجتها داخل Provider نفسه
      final provider = Provider.of<ConsultantArticleProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteArticle(context, articleId);
        // بعد النجاح، عرض رسالة
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
        // setState(() { _isDeleting = false; }); // مثال
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ConsultantArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقالاتي'),
        actions: [
          // زر إضافة مقال جديد
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: articleProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
              // الانتقال إلى شاشة إضافة مقال جديد (CreateEditArticleScreen)
              print('Add Article Tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  // نمرر null لـ article للإشارة إلى أنها شاشة إضافة
                  builder: (context) => const CreateEditArticleScreen(article: null),
                ),
              );
            },
          ),
        ],
      ),
      body: articleProvider.isLoading && articleProvider.managedArticles.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : articleProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${articleProvider.error}'))
          : articleProvider.managedArticles.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لم تنشر أي مقالات بعد.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: articleProvider.managedArticles.length + (articleProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == articleProvider.managedArticles.length) {
            // إذا كنا في حالة جلب المزيد، اعرض مؤشر
            return articleProvider.isFetchingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(); // وإلا لا تعرض شيئاً
          }

          final article = articleProvider.managedArticles[index];
          // تأكد أن المقال لديه ID قبل عرض أزرار التعديل/الحذف أو الانتقال
          if (article.articleId == null) return const SizedBox.shrink();


          return ListTile(
            title: Text(article.title ?? 'بدون عنوان'),
            subtitle: Text('النوع: ${article.type ?? 'غير معروف'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر تعديل مقال
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: articleProvider.isLoading ? null : () { // تعطيل الزر أثناء تحميل أي عملية في Provider
                    // الانتقال إلى شاشة تعديل مقال
                    print('Edit Article Tapped for ID ${article.articleId}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // نمرر كائن المقال لـ CreateEditArticleScreen للإشارة إلى أنها شاشة تعديل
                        builder: (context) => CreateEditArticleScreen(article: article),
                      ),
                    );
                  },
                ),
                // زر حذف مقال
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: articleProvider.isLoading ? null : () { // تعطيل الزر أثناء التحميل
                    _deleteArticle(article.articleId!); // استدعاء تابع الحذف
                  },
                ),
              ],
            ),
            onTap: articleProvider.isLoading ? null : () { // تعطيل النقر أثناء التحميل
              // الانتقال لتفاصيل المقال
              print('Article Tapped: ${article.articleId}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConsultantArticleDetailScreen(article: article), // <--- الانتقال لشاشة التفاصيل
                ),
              );
            },
          );
        },
      ),
    );
  }
}