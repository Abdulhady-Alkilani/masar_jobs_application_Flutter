import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consultant_article_provider.dart';
import '../models/article.dart';
import 'consultant_article_detail_screen.dart'; // تأكد من المسار
// استيراد شاشة إضافة مقال جديد


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
    Provider.of<ConsultantArticleProvider>(context, listen: false).fetchManagedArticles(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<ConsultantArticleProvider>(context, listen: false).fetchMoreManagedArticles(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ConsultantArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقالاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: الانتقال إلى شاشة إضافة مقال جديد (CreateArticleScreen)
              print('Add Article Tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة إضافة مقال لم تنفذ.')),
              );
            },
          ),
        ],
      ),
      body: articleProvider.isLoading && articleProvider.managedArticles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : articleProvider.error != null
          ? Center(child: Text('Error: ${articleProvider.error}'))
          : articleProvider.managedArticles.isEmpty
          ? const Center(child: Text('لم تنشر أي مقالات بعد.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: articleProvider.managedArticles.length + (articleProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == articleProvider.managedArticles.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = articleProvider.managedArticles[index];
          return ListTile(
            title: Text(article.title ?? 'بدون عنوان'),
            subtitle: Text(article.type ?? 'غير معروف'),
            trailing: Text(article.date?.toString().split(' ')[0] ?? ''),
            onTap: () {
              // الانتقال لتفاصيل المقال (للاستشاري)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConsultantArticleDetailScreen(article: article), // يمكن تمرير الكائن مباشرة إذا كان موجوداً
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشة CreateArticleScreen لإضافة مقال جديد (ستحتاج ConsultantArticleProvider.createArticle)