// lib/screens/public_views/public_article_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
// ستحتاج مكتبة url_launcher لفتح الروابط إذا وجدت في المحتوى أو كجزء من المقال
// import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher_string.dart';

import '../../models/article.dart';
import '../../providers/public_article_provider.dart';
import '../../services/api_service.dart'; // لاستخدام ApiException

class PublicArticleDetailsScreen extends StatefulWidget {
  final int articleId;

  const PublicArticleDetailsScreen({super.key, required this.articleId});

  @override
  State<PublicArticleDetailsScreen> createState() => _PublicArticleDetailsScreenState();
}

class _PublicArticleDetailsScreenState extends State<PublicArticleDetailsScreen> {
  // لا حاجة لتهيئة Provider هنا، سيتم استخدامه في FutureBuilder

  // !!! استبدل هذا الرابط بعنوان موقعك الأساسي إذا لم يكن موجوداً في ApiService أو مكان عام !!!
  // يمكن أيضاً إضافة baseUrl كـ static const في ApiService أو Util Class
  static const String baseUrl = 'https://powderblue-woodpecker-887296.hostingersite.com';


  @override
  Widget build(BuildContext context) {
    // يمكن الوصول إلى Provider للاستدعاء فقط (listen: false) إذا لزم الأمر
    // final articleProvider = Provider.of<PublicArticleProvider>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المقال'), // يمكن تغيير العنوان لاحقاً بعد جلب البيانات
      ),
      // استخدام FutureBuilder لجلب بيانات المقال عند بناء الشاشة
      body: FutureBuilder<Article?>(
        // استخدام تابع جلب المقال الفردي من Provider
        // نستخدم listen: false لأننا داخل FutureBuilder ونريد فقط النتيجة الأولية المستقبلية
        future: Provider.of<PublicArticleProvider>(context, listen: false).fetchArticle(widget.articleId),
        builder: (context, snapshot) {
          // حالات التحميل والخطأ والبيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // عرض خطأ من الـ Provider إذا كان متاحاً، أو خطأ snapshot
            // هنا نستخدم listen: false للحفاظ على الأداء داخل FutureBuilder
            final provider = Provider.of<PublicArticleProvider>(context, listen: false);
            final errorMessage = provider.error ?? snapshot.error?.toString() ?? 'حدث خطأ غير معروف';
            return Center(child: Text('حدث خطأ: $errorMessage'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('لم يتم العثور على المقال.'));
          } else {
            // عرض تفاصيل المقال بعد جلبها بنجاح
            final article = snapshot.data!;
            final imageUrl = (article.articlePhoto != null && article.articlePhoto!.isNotEmpty)
                ? baseUrl + article.articlePhoto!
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة المقال
                  if (imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
                        ),
                      ),
                    ),

                  Text(
                    article.title ?? 'بدون عنوان',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نوع المقال: ${article.type ?? 'غير محدد'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  if (article.date != null)
                    Text(
                      'تاريخ النشر: ${DateFormat.yMMMd('ar').format(article.date!)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  // كاتب المقال
                  if (article.user != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          // backgroundImage: NetworkImage(...) إذا كان للمستخدم صورة في الموديل
                          child: Text(article.user!.firstName?.isNotEmpty == true ? article.user!.firstName![0] : '?', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الكاتب: ${article.user!.firstName} ${article.user!.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'المحتوى:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description ?? 'لا يوجد محتوى لهذا المقال.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24), // مساحة إضافية قبل التواريخ
                  Text(
                    'أنشئ في: ${article.createdAt != null ? DateFormat.yMMMd('ar').add_Hms().format(article.createdAt!) : 'غير متاح'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'حدث في: ${article.updatedAt != null ? DateFormat.yMMMd('ar').add_Hms().format(article.updatedAt!) : 'غير متاح'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),


                ],
              ),
            );
          }
        },
      ),
    );
  }
}