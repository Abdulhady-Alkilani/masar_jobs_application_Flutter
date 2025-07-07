// lib/screens/public_views/public_articles_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masar_jobs/screens/public/public_article_details_screen.dart';
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

    // --- 2. هنا التعديل ---
    return RiveRefreshIndicator( // <-- استخدام الويدجت الجديدة بدلاً من RefreshIndicator
      onRefresh: () => provider.fetchArticles(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: provider.articles.length,
        itemBuilder: (context, index) {
          final article = provider.articles[index];
          return ArticleCard(article: article)
              .animate(delay: (120 * (index % 10)).ms)
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
        },
      ),
    );
  }

  // ... (باقي الكود: _buildShimmerLoading و ArticleCard يبقى كما هو)
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
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class ArticleCard extends StatefulWidget {
  final Article article;
  const ArticleCard({Key? key, required this.article}) : super(key: key);
  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 1.05 : 1.0,
        child: Card(
          elevation: _isHovered ? 12 : 4,
          shadowColor: _isHovered ? Theme.of(context).colorScheme.secondary.withOpacity(0.3) : Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailsScreen(article: widget.article),
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.article.articlePhoto != null && widget.article.articlePhoto!.isNotEmpty)
                  Image.network(
                    widget.article.articlePhoto!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  )
                else
                  Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.article_outlined, size: 60, color: Colors.grey.shade400),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article.title ?? 'عنوان المقال',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black54)]
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بقلم: ${widget.article.user?.firstName ?? ''}',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}