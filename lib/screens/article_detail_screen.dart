import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_article_provider.dart'; // نستخدم نفس Provider العام
import '../models/article.dart'; // تأكد من المسار

class ArticleDetailScreen extends StatelessWidget {
  final int articleId; // معرف المقال الذي سنعرض تفاصيله

  const ArticleDetailScreen({Key? key, required this.articleId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // نستخدم FutureBuilder لجلب المقال المحدد عند بناء الشاشة
    // أو يمكنك استخدام Provider.select للحصول على المقال من القائمة المحملة مسبقاً إذا كانت موجودة
    final articleProvider = Provider.of<PublicArticleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المقال'),
      ),
      body: FutureBuilder<Article?>( // استخدم FutureBuilder لجلب المقال
        future: articleProvider.fetchArticle(articleId), // استدعاء تابع جلب مقال محدد
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // عرض خطأ من Provider (أو خطأ جلب البيانات)
            final error = articleProvider.error ?? snapshot.error?.toString() ?? 'حدث خطأ غير متوقع';
            return Center(child: Text('Error: $error'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('المقال غير موجود.'));
          } else {
            final article = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title ?? 'بدون عنوان',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بواسطة: ${article.user?.firstName ?? ''} ${article.user?.lastName ?? ''}',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  Text(
                    'تاريخ النشر: ${article.date?.toString().split(' ')[0] ?? 'غير معروف'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  // عرض الصورة إذا كانت موجودة
                  if (article.articlePhoto != null && article.articlePhoto!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Image.network(
                        'http://127.0.0.1:8000${article.articlePhoto!}', // تأكد من عنوان URL الصحيح للصور الثابتة
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image), // أيقونة عند فشل تحميل الصورة
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    article.description ?? 'لا يوجد وصف متاح.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  // يمكنك إضافة المزيد من التفاصيل هنا
                ],
              ),
            );
          }
        },
      ),
    );
  }
}