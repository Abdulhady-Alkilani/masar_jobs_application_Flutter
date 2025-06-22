// lib/screens/public_articles_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../providers/public_article_provider.dart';
import '../../models/article.dart';
// import 'article_details_screen.dart'; // شاشة لعرض تفاصيل المقال (سنحتاج لإنشائها)

class PublicArticlesListScreen extends StatefulWidget {
  const PublicArticlesListScreen({super.key});

  @override
  State<PublicArticlesListScreen> createState() => _PublicArticlesListScreenState();
}

class _PublicArticlesListScreenState extends State<PublicArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PublicArticleProvider>(context, listen: false);

    // جلب الصفحة الأولى
    // تأكد من أن القائمة فارغة قبل الجلب لتجنب تراكم البيانات عند العودة للشاشة
    if (provider.articles.isEmpty) {
      provider.fetchArticles();
    }

    // مستمع للتمرير لجلب المزيد
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreArticles();
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('المقالات والأخبار'),
      ),
      body: Consumer<PublicArticleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.articles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.articles.isEmpty) {
            return Center(child: Text('حدث خطأ: ${provider.error}'));
          }

          if (provider.articles.isEmpty) {
            return const Center(child: Text('لا توجد مقالات متاحة حالياً.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchArticles(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.articles.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.articles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final article = provider.articles[index];
                return _buildArticleCard(context, article);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    // !!! استبدل هذا الرابط بعنوان موقعك الأساسي !!!
    const String baseUrl = 'https://powderblue-woodpecker-887296.hostingersite.com';
    final imageUrl = (article.articlePhoto != null && article.articlePhoto!.isNotEmpty)
        ? baseUrl + article.articlePhoto!
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // لقص الصورة لتناسب زوايا البطاقة
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // TODO: الانتقال إلى شاشة تفاصيل المقال
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailsScreen(article: article)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المقال
            if (imageUrl != null)
              Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
              ),

            // محتوى البطاقة
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title ?? 'بدون عنوان',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      // كاتب المقال
                      if (article.user != null) ...[
                        CircleAvatar(
                          radius: 15,
                          // backgroundImage: NetworkImage(...) إذا كان للمستخدم صورة
                          child: Text(article.user!.firstName?.substring(0,1) ?? '?'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${article.user!.firstName} ${article.user!.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                      const Spacer(),
                      // تاريخ النشر
                      if (article.date != null)
                        Text(
                          DateFormat.yMMMd('ar').format(article.date!), // تنسيق عربي للتاريخ
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}