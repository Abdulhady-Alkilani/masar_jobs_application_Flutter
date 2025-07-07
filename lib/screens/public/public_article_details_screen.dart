// lib/screens/details/article_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart'; // لاستخدامه في تحميل الصور
import '../../models/article.dart';

class ArticleDetailsScreen extends StatelessWidget {
  final Article article;
  const ArticleDetailsScreen({Key? key, required this.article}) : super(key: key);

  // دالة لفتح الرابط
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    // --- خطوة تشخيصية: طباعة الرابط قبل محاولة فتحه ---
    print("Attempting to launch URL: $urlString");

    // التأكد من أن الرابط كامل
    if (!urlString.startsWith('http')) {
      // يمكنك إضافة عنوان السيرفر الأساسي هنا إذا كانت الروابط نسبية
      // urlString = "https://your-server.com" + urlString;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرابط غير صالح: $urlString')),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن فتح الرابط: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- جمل الطباعة التشخيصية ---
    print("--- Building ArticleDetailsScreen ---");
    print("Article Title: ${article.title}");
    print("Article Photo URL from API: ${article.articlePhoto}");
    print("Article PDF Link from API: ${article.pdfLink}");
    // -----------------------------

    final theme = Theme.of(context);
    final bool hasPdf = article.pdfLink != null && article.pdfLink!.isNotEmpty;
    final bool hasPhoto = article.articlePhoto != null && article.articlePhoto!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. الشريط العلوي (Header) مع الصورة
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            backgroundColor: theme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                article.title ?? 'تفاصيل المقال',
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
                article.articlePhoto!,
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
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 60)),
              )
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.article_outlined, color: Colors.white24, size: 150),
              ),
            ),
          ),

          // 2. محتوى الصفحة
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Text(
                        article.user?.firstName?.substring(0, 1) ?? 'A',
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    title: Text(
                      'بقلم: ${article.user?.firstName ?? 'خبير'} ${article.user?.lastName ?? ''}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'تاريخ النشر: ${article.date != null ? DateFormat('dd MMMM yyyy', 'ar').format(article.date!) : 'غير محدد'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const Divider(height: 32),

                  Text(
                    article.description ?? 'لا يوجد محتوى لهذا المقال.',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 18),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),

                  if (hasPdf) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(context, article.pdfLink!),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('تحميل الملف المرفق (PDF)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: theme.colorScheme.error.withOpacity(0.9),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ).animate(delay: 600.ms).scale(),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}