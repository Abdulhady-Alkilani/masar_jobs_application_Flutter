// lib/screens/admin/articles/admin_article_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator
// ستحتاج مكتبة url_launcher لفتح الرابط إذا كان موجوداً
// import 'package:url_launcher/url_launcher.dart';

import '../../../models/article.dart';
import '../../../providers/admin_article_provider.dart';
import 'admin_create_edit_article_screen.dart';

class AdminArticleDetailsScreen extends StatefulWidget {
  final int articleId;

  const AdminArticleDetailsScreen({super.key, required this.articleId});

  @override
  State<AdminArticleDetailsScreen> createState() => _AdminArticleDetailsScreenState();
}

class _AdminArticleDetailsScreenState extends State<AdminArticleDetailsScreen> {
  // يمكن جلب المقال هنا أو الاعتماد على Provider لجلبه عند الحاجة
  // سنستخدم FutureBuilder لجلب التفاصيل عند بناء الشاشة

  @override
  Widget build(BuildContext context) {
    // يمكن الوصول إلى Provider للاستدعاء فقط (listen: false)
    final articleProvider = Provider.of<AdminArticleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المقال (أدمن)'),
        actions: [
          // زر للتعديل (يمكن نقلك إلى نفس شاشة الإنشاء مع تمرير بيانات المقال)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل المقال',
            onPressed: () async {
              // جلب أحدث بيانات للمقال للتأكد عند التعديل
              final Article? articleToEdit = await articleProvider.fetchSingleArticle(context, widget.articleId);
              if (articleToEdit != null) {
                // TODO: الانتقال إلى شاشة التعديل مع تمرير المقال
                 Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCreateEditArticleScreen(article: articleToEdit,)));
              } else {
                // التعامل مع خطأ إذا لم يتم العثور على المقال
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يمكن تحميل بيانات المقال للتعديل')),
                );
              }
            },
          ),
          // زر للحذف (يمكن أن يتم التعامل معه هنا مباشرة أو في شاشة القائمة)
          // التعامل معه هنا يتطلب إعادة التوجيه بعد الحذف
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'حذف المقال',
            onPressed: () async {
              final bool? confirmDelete = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: const Text('هل أنت متأكد أنك تريد حذف هذا المقال؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('حذف'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                try {
                  // استدعاء تابع الحذف من Provider
                  await articleProvider.deleteArticle(context, widget.articleId);
                  // عرض رسالة نجاح والعودة إلى شاشة القائمة
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المقال بنجاح')),
                  );
                  Navigator.of(context).pop(); // العودة بعد الحذف
                } catch (e) {
                  // التعامل مع الخطأ
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل حذف المقال: ${articleProvider.error}')),
                  );
                }
              }
            },
          ),
        ],
      ),
      // استخدام FutureBuilder لجلب البيانات الفردية عند الطلب
      body: FutureBuilder<Article?>(
        // استخدام تابع جلب المقال الفردي من Provider
        future: articleProvider.fetchSingleArticle(context, widget.articleId),
        builder: (context, snapshot) {
          // حالات التحميل والخطأ والبيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: RiveLoadingIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('لم يتم العثور على المقال.'));
          } else {
            // عرض تفاصيل المقال بعد جلبها بنجاح
            final article = snapshot.data!;
            // !!! استبدل هذا الرابط بعنوان موقعك الأساسي إذا لم يكن موجوداً في ApiService أو مكان عام !!!
            // يمكنك أيضاً إضافة baseUrl كـ static const في ApiService أو Util Class
            const String baseUrl = 'https://powderblue-woodpecker-887296.hostingersite.com';
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
                      'تاريخ الن��ر: ${DateFormat.yMMMd('ar').format(article.date!)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  // كاتب المقال
                  if (article.user != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          // backgroundImage: NetworkImage(...) إذا كان للمستخدم صورة
                          child: Text(article.user!.firstName?.substring(0,1) ?? '?', style: TextStyle(fontSize: 18)),
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