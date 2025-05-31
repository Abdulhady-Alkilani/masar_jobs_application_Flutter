import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_article_provider.dart'; // تأكد من المسار
import '../models/article.dart'; // تأكد من المسار
import 'admin_article_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة/تعديل مقال


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
    Provider.of<AdminArticleProvider>(context, listen: false).fetchAllArticles(context);

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

  // TODO: تابع لحذف مقال (adminArticleProvider.deleteArticle) مع تأكيد

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<AdminArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المقالات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة مقال جديد (CreateEditArticleScreen)
              print('Add Article Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة مقال لم تنفذ.')),
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
          return ListTile(
            title: Text(article.title ?? 'بدون عنوان'),
            subtitle: Text('المؤلف UserID: ${article.userId ?? 'غير محدد'} - النوع: ${article.type ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: () {
                    // TODO: الانتقال إلى شاشة تعديل مقال (CreateEditArticleScreen) مع تمرير بيانات المقال
                    print('Edit Article Tapped for ID ${article.articleId}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة تعديل مقال لم تنفذ.')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: () {
                    if (article.articleId != null) {
                      // TODO: تابع لحذف المقال (adminArticleProvider.deleteArticle) مع تأكيد
                      print('Delete Article Tapped for ID ${article.articleId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('وظيفة حذف مقال لم تنفذ.')),
                      );
                    }
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

// TODO: أنشئ شاشة CreateEditArticleScreen لإضافة أو تعديل مقال (تحتاج AdminArticleProvider.createArticle و .updateArticle)
// TODO: أنشئ شاشة AdminArticleDetailScreen لعرض تفاصيل مقال (تحتاج AdminArticleProvider.fetchArticle أو استخدام public fetch)