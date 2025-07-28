// lib/screens/public_articles_list_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masar_jobs/screens/public/public_article_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../providers/public_article_provider.dart';
import '../models/article.dart';
import 'widgets/empty_state_widget.dart';

class PublicArticlesListScreen extends StatefulWidget {
  final bool isGuest;
  const PublicArticlesListScreen({super.key, this.isGuest = false});

  @override
  State<PublicArticlesListScreen> createState() => _PublicArticlesListScreenState();
}

class _PublicArticlesListScreenState extends State<PublicArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PublicArticleProvider>(context, listen: false);

    if (provider.articles.isEmpty) {
      provider.fetchArticles();
    }

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
      backgroundColor: Colors.grey.shade100,
      body: Consumer<PublicArticleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.articles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.articles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.cloud_off_rounded,
              title: 'حدث خطأ',
              message: 'لم نتمكن من جلب المقالات. حاول تحديث الصفحة.',
              onRefresh: () => provider.fetchArticles(),
            );
          }

          if (provider.articles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'لا توجد مقالات',
              message: 'لم يتم نشر أي مقالات بعد. تحقق مرة ��خرى قريبًا!',
              onRefresh: () => provider.fetchArticles(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchArticles(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.articles.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.articles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final article = provider.articles[index];
                return _buildArticleCard(context, article)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (100 * (index % 5)).ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    final theme = Theme.of(context);
    final imageUrl = article.articlePhoto;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailsScreen(article: article),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Card Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Text(
                      article.user?.firstName?.substring(0, 1) ?? 'A',
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${article.user?.firstName ?? 'خبير'} ${article.user?.lastName ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (article.date != null)
                          Text(
                            DateFormat.yMMMd('ar').add_jm().format(article.date!),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- Card Image ---
            if (imageUrl != null)
              Hero(
                tag: 'article_image_${article.articleId}',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                  ),
                ),
              ),
            // --- Card Content ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                article.title ?? 'بدون عنوان',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (article.description != null && article.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                child: Text(
                  article.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // --- Card Footer ---
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailsScreen(article: article),
                        ),
                      );
                    },
                    icon: const Icon(Icons.read_more_outlined),
                    label: const Text('قراءة المزيد'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}