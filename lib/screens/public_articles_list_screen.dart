import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_article_provider.dart';
import '../models/article.dart'; // تأكد من المسار
import 'article_detail_screen.dart'; // تأكد من المسار

class PublicArticlesListScreen extends StatefulWidget {
  const PublicArticlesListScreen({Key? key}) : super(key: key);

  @override
  _PublicArticlesListScreenState createState() => _PublicArticlesListScreenState();
}

class _PublicArticlesListScreenState extends State<PublicArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب المقالات عند تهيئة الشاشة
    Provider.of<PublicArticleProvider>(context, listen: false).fetchArticles();

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        // المستخدم وصل لنهاية القائمة، جلب المزيد
        Provider.of<PublicArticleProvider>(context, listen: false).fetchMoreArticles();
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
    // الاستماع لحالة Provider
    final articleProvider = Provider.of<PublicArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المقالات'),
      ),
      body: articleProvider.isLoading && articleProvider.articles.isEmpty // التحميل الأولي
          ? const Center(child: CircularProgressIndicator())
          : articleProvider.error != null // عرض الخطأ
          ? Center(child: Text('Error: ${articleProvider.error}'))
          : articleProvider.articles.isEmpty // لا توجد بيانات
          ? const Center(child: Text('لا توجد مقالات متاحة حالياً.'))
          : ListView.builder(
        controller: _scrollController, // ربط الـ ScrollController
        itemCount: articleProvider.articles.length + (articleProvider.isFetchingMore ? 1 : 0), // إضافة عنصر تحميل في النهاية
        itemBuilder: (context, index) {
          // عرض عنصر التحميل في النهاية
          if (index == articleProvider.articles.length) {
            return const Center(child: CircularProgressIndicator());
          }

          // عرض بيانات المقال
          final article = articleProvider.articles[index];
          return ListTile(
            title: Text(article.title ?? 'بدون عنوان'),
            subtitle: Text(article.description?.split('\n')[0] ?? 'لا يوجد وصف'), // عرض السطر الأول من الوصف
            trailing: Text(article.date?.toString().split(' ')[0] ?? ''), // عرض التاريخ فقط
            onTap: () {
              // الانتقال إلى شاشة تفاصيل المقال
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailScreen(articleId: article.articleId!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}