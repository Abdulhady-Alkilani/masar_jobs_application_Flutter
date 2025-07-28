// lib/screens/consultant/articles/managed_articles_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/consultant_article_provider.dart';
import '../../../models/article.dart';
import '../../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:masar_jobs/screens/consultant/articles/managed_article_details_screen.dart';
import 'create_edit_article_screen.dart';
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class ManagedArticlesListScreen extends StatefulWidget {
  const ManagedArticlesListScreen({super.key});
  @override
  State<ManagedArticlesListScreen> createState() => _ManagedArticlesListScreenState();
}

class _ManagedArticlesListScreenState extends State<ManagedArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ConsultantArticleProvider>(context, listen: false);
      provider.fetchManagedArticles(context);
    });
    final provider = Provider.of<ConsultantArticleProvider>(context, listen: false);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreManagedArticles(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteArticle(Article article, ConsultantArticleProvider provider) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المقال؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      try {
        await provider.deleteArticle(context, article.articleId!);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('تم حذف المقال بنجاح'),
            backgroundColor: theme.colorScheme.secondary,
          ),
        );
      } on ApiException catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف المقال: ${e.message}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مقالاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة مقال جديد',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditArticleScreen()));
            },
          ),
        ],
      ),
      body: Consumer<ConsultantArticleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.managedArticles.isEmpty) {
            return const Center(child: RiveLoadingIndicator());
          }
          if (provider.error != null && provider.managedArticles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'حدث خطأ',
              message: 'لم نتمكن من جلب مقالاتك. حاول تحديث الصفحة.',
              onRefresh: () => provider.fetchManagedArticles(context),
            );
          }
          if (provider.managedArticles.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'ابدأ بالكتابة!',
              message: 'لم تقم بنشر أي مقالات بعد. اضغط على زر الإضافة لمشاركة معرفتك.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchManagedArticles(context),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.managedArticles.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.managedArticles.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: RiveLoadingIndicator()));
                }
                final article = provider.managedArticles[index];
                return _buildArticleCard(article, provider)
                    .animate(delay: (100 * (index % 10)).ms)
                    .fadeIn()
                    .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(Article article, ConsultantArticleProvider provider) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManagedArticleDetailsScreen(article: article),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background Image
            Container(
              height: 220,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(article.articlePhoto ?? 'https://source.unsplash.com/random/800x600?sig=${article.articleId}'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title ?? 'بدون عنوان',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'تاريخ النشر: ${article.date?.toLocal().toString().substring(0, 10) ?? 'غير معروف'}',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditArticleScreen(article: article)));
                  } else if (value == 'delete') {
                    _deleteArticle(article, provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                ],
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}