import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masar_jobs/screens/public/public_article_details_screen.dart';
import 'package:masar_jobs/screens/public/public_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/public_article_provider.dart';
import '../../models/article.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/rive_refresh_indicator.dart';

class PublicArticlesView extends StatefulWidget {
  const PublicArticlesView({super.key});
  @override
  State<PublicArticlesView> createState() => _PublicArticlesViewState();
}

class _PublicArticlesViewState extends State<PublicArticlesView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicArticleProvider>(context, listen: false);
      if (p.articles.isEmpty) p.fetchArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<PublicArticleProvider>();
    
    // The background is now handled by the HomeScreen gradient
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.articles.isEmpty) {
            return _buildShimmerLoading();
          }
          if (provider.error != null && provider.articles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.cloud_off_rounded,
              title: 'خطأ في الاتصال',
              message: 'لا يمكن عرض المقالات حالياً. تأكد من اتصالك بالشبكة.',
              onRefresh: () => provider.fetchArticles(),
            );
          }
          if (provider.articles.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'لا توجد مقالات بعد',
              message: 'خبراؤنا يعملون على كتابة محتوى مفيد ومميز. عد قريباً للاطلاع على كل جديد!',
            );
          }

          return RiveRefreshIndicator(
            onRefresh: () => provider.fetchArticles(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.articles.length,
              itemBuilder: (context, index) {
                final article = provider.articles[index];
                return ArticleCard(article: article)
                    .animate(delay: (100 * (index % 5)).ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Article article;
  const ArticleCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 8, // Increased elevation for a more prominent shadow
      shadowColor: Colors.black.withOpacity(0.2), // More visible shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded corners
        side: BorderSide(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
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
            // --- Header: Author Info ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person_outline, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (article.user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PublicProfileScreen(userId: article.user!.userId!),
                            ),
                          );
                        }
                      },
                      child: Text(
                        article.user?.firstName ?? 'كاتب غير معروف',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // --- Article Image ---
            if (article.articlePhoto != null && article.articlePhoto!.isNotEmpty)
              Image.network(
                article.articlePhoto!,
                fit: BoxFit.cover,
                height: 200, // Fixed height for consistency
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(color: Colors.white, height: 200),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              )
            else
              Container(
                height: 150,
                color: Colors.grey.shade200,
                child: Icon(Icons.article_outlined, size: 60, color: Colors.grey.shade400),
              ),
            // --- Article Title ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: Text(
                article.title ?? 'عنوان المقال',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // --- Article Description Snippet ---
            if (article.description != null && article.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  article.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Divider(height: 20),
            // --- Actions: Like and Read More ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like Button and Count
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        color: theme.primaryColor,
                        onPressed: () {
                          // TODO: Implement like/unlike functionality for articles
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Like Article functionality coming soon!')),
                          );
                        },
                      ),
                      Text(
                        '123', // Placeholder for like count
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  // Read More Button
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
                    label: const Text('عرض التفاصيل'),
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
