import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_article_provider.dart'; // لتنفيذ عمليات الحذف والإنشاء
import '../models/article.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO
import 'admin_article_detail_screen.dart'; // شاشة التفاصيل
import 'create_edit_article_screen.dart'; // <--- شاشة إضافة/تعديل المقال


class AdminArticlesListScreen extends StatefulWidget {
  const AdminArticlesListScreen({Key? key}) : super(key: key);

  @override
  _AdminArticlesListScreenState createState() => _AdminArticlesListScreenState();
}

class _AdminArticlesListScreenState extends State<AdminArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب قائمة المقالات عند تهيئة الشاشة
    Provider.of<AdminArticleProvider>(context, listen: false).fetchAllArticles(context);

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<AdminArticleProvider>(context, listen: false).fetchMoreArticles(context);
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
      // setState(() { _isDeleting = true; }); // بداية التحميل للحذف
      final provider = Provider.of<AdminArticleProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteArticle(context, articleId);
        // بعد النجاح، عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المقال بنجاح.')),
        );
        // لا نحتاج العودة للشاشة السابقة هنا، لأننا بالفعل في شاشة القائمة
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
        // setState(() { _isDeleting = false; }); // انتهاء التحميل للحذف
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<AdminArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المقالات'),
        actions: [
          // زر إضافة مقال جديد
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
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
      body: articleProvider.isLoading && articleProvider.articles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : articleProvider.error != null
          ? Center(child: Text('Error: ${articleProvider.error}'))
          : articleProvider.articles.isEmpty
          ? const Center(child: Text('لا توجد مقالات.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: articleProvider.articles.length + (articleProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == articleProvider.articles.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = articleProvider.articles[index];
          // تأكد أن المقال لديه ID قبل عرض أزرار التعديل/الحذف
          if (article.articleId == null) return const SizedBox.shrink();

          return ListTile(
            title: Text(article.title ?? 'بدون عنوان'),
            subtitle: Text('المؤلف UserID: ${article.userId ?? 'غير محدد'} - النوع: ${article.type ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر تعديل مقال
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: () {
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
                  onPressed: () {
                    _deleteArticle(article.articleId!); // استدعاء تابع الحذف
                  },
                ),
              ],
            ),
            onTap: () {
              // الانتقال لتفاصيل المقال
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminArticleDetailScreen(articleId: article.articleId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}