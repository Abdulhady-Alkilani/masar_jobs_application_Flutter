import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:masar_jobs/models/article.dart';
import 'package:masar_jobs/screens/public/public_profile_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/rive_loading_indicator.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailsScreen({Key? key, required this.article}) : super(key: key);

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  Future<String>? _pdfPathFuture;

  @override
  void initState() {
    super.initState();
    if (widget.article.pdfLink != null && widget.article.pdfLink!.isNotEmpty) {
      _pdfPathFuture = _downloadFile(widget.article.pdfLink!);
    }
  }

  Future<String> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        // Use a unique name to avoid caching issues
        final file = File('${dir.path}/${widget.article.articleId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } else {
        throw Exception('Failed to download PDF: Status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPdf = widget.article.pdfLink != null && widget.article.pdfLink!.isNotEmpty;
    final imageUrl = widget.article.articlePhoto;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Very light sky blue
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white, // AppBar background white
            iconTheme: IconThemeData(color: theme.primaryColor), // Icons in primary color
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                widget.article.title ?? 'تفاصيل المقال',
                style: TextStyle(
                  color: theme.primaryColor, // Title in primary color
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.3))],
                ),
                textAlign: TextAlign.center,
              ),
              background: Hero(
                tag: 'article_image_${widget.article.articleId}',
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.2), // Slightly less dark overlay
                        colorBlendMode: BlendMode.darken,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(color: Colors.white));
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 60)),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Color(0xFFE0F7FA)], // White to light sky blue gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(Icons.article_outlined, color: theme.primaryColor.withOpacity(0.2), size: 150),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorInfo(context, theme),
                  const SizedBox(height: 24),
                  // Removed redundant title as it's already in the SliverAppBar
                  Text(
                    widget.article.description ?? 'لا يوجد محتوى لهذا المقال.',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 17, color: Colors.black.withOpacity(0.7)),
                  ).animate().fadeIn(delay: 400.ms),
                  if (hasPdf) ...[
                    const Divider(height: 48),
                    _buildPdfSection(theme),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (widget.article.user != null) {
          Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: widget.article.user!.userId!)),
                      );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(
              widget.article.user?.firstName?.substring(0, 1) ?? 'A',
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بقلم: ${widget.article.user?.firstName ?? 'خبير'} ${widget.article.user?.lastName ?? ''}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'تاريخ النشر: ${widget.article.date != null ? DateFormat('d MMMM yyyy', 'ar').format(widget.article.date!) : 'غير محدد'}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
    );
  }

  Widget _buildPdfSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الملف المرفق (PDF)',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Center(
          child: FutureBuilder<String>(
            future: _pdfPathFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    RiveLoadingIndicator(),
                    SizedBox(height: 8),
                    Text('جاري تحميل الملف...'),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('خطأ في تحميل الملف: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return SizedBox(
                  height: 600,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PDFView(
                      filePath: snapshot.data!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageFling: true,
                    ),
                  ),
                );
              } else {
                return const Text('لا يوجد ملف PDF لعرضه.');
              }
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}