import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:masar_jobs/models/article.dart';
import 'package:masar_jobs/screens/consultant/articles/create_edit_article_screen.dart';
import 'package:masar_jobs/screens/widgets/neumorphic_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class ManagedArticleDetailsScreen extends StatefulWidget {
  final Article article;
  const ManagedArticleDetailsScreen({Key? key, required this.article}) : super(key: key);

  @override
  State<ManagedArticleDetailsScreen> createState() => _ManagedArticleDetailsScreenState();
}

class _ManagedArticleDetailsScreenState extends State<ManagedArticleDetailsScreen> {
  Future<String>? pdfPath;

  @override
  void initState() {
    super.initState();
    if (widget.article.pdfLink != null && widget.article.pdfLink!.isNotEmpty) {
      pdfPath = _downloadFile(widget.article.pdfLink!);
    }
  }

  Future<String> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasPdf = widget.article.pdfLink != null && widget.article.pdfLink!.isNotEmpty;
    final bool hasPhoto = widget.article.articlePhoto != null && widget.article.articlePhoto!.isNotEmpty;
    const backgroundColor = Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            backgroundColor: theme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل المقال',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEditArticleScreen(article: widget.article),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                widget.article.title ?? 'تفاصيل المقال',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: hasPhoto
                  ? Image.network(
                      widget.article.articlePhoto!,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                            baseColor: Colors.grey.shade600,
                            highlightColor: Colors.grey.shade500,
                            child: Container(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 60)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child:
                          const Icon(Icons.article_outlined, color: Colors.white24, size: 150),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NeumorphicCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ النشر: ${widget.article.date != null ? DateFormat('dd MMMM yyyy', 'ar').format(widget.article.date!) : 'غير محدد'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                    const Divider(height: 32),
                    Text(
                      widget.article.description ?? 'لا يوجد محتوى لهذا المقال.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 18),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                    if (hasPdf) ...[
                      const SizedBox(height: 40),
                      const Center(
                        child: Text(
                          'الملف المرفق (PDF)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<String>(
                        future: pdfPath,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: RiveLoadingIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('خطأ في تحميل الملف: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            return Container(
                              height: 500,
                              child: PDFView(
                                filePath: snapshot.data!,
                              ),
                            );
                          } else {
                            return const Center(child: Text('لا يوجد ملف PDF لعرضه'));
                          }
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}