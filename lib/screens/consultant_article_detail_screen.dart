import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consultant_article_provider.dart'; // لتنفيذ عمليات التحديث/الحذف
import '../models/article.dart';

class ConsultantArticleDetailScreen extends StatelessWidget {
  final Article article; // يمكن تمرير المقال مباشرة إذا تم جلبه في الشاشة السابقة

  const ConsultantArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  // في هذه الشاشة، نستخدم Provider فقط لتنفيذ الإجراءات (تحديث، حذف)
  // لا نحتاج لجلب بيانات المقال هنا مرة أخرى إذا تم تمريره.
  // إذا لم يتم تمريره، ستحتاج لجلب تفاصيله (مثل fetchArticle في Provider العام أو تابع خاص هنا).

  // تابع لحذف المقال
  Future<void> _deleteArticle(BuildContext context, int articleId) async {
    final articleProvider = Provider.of<ConsultantArticleProvider>(context, listen: false);
    try {
      // TODO: إضافة تأكيد قبل الحذف (AlertDialog)
      await articleProvider.deleteArticle(context, articleId);
      // بعد الحذف، العودة إلى شاشة قائمة المقالات
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المقال بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف المقال: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // إذا لم يتم تمرير المقال، يمكنك استخدام FutureBuilder هنا لجلبه باستخدام ID
    // لكن تمرير الكائن مباشرة أسهل إذا كان متاحاً.

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title ?? 'تفاصيل المقال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: الانتقال إلى شاشة تعديل المقال (EditArticleScreen) أو فتح نموذج
              print('Edit Article Tapped for ID ${article.articleId}');
              // Navigator.push(context, MaterialPageRoute(builder: (context) => EditArticleScreen(article: article)));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('وظيفة تعديل المقال لم تنفذ.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              if (article.articleId != null) {
                _deleteArticle(context, article.articleId!);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المقال (مشابه لشاشة التفاصيل العامة)
            Text(
              article.title ?? 'بدون عنوان',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'النوع: ${article.type ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 16),
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
                  'http://127.0.0.1:8000${article.articlePhoto!}', // تأكد من URL الصحيح
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              article.description ?? 'لا يوجد وصف متاح.',
              style: const TextStyle(fontSize: 16),
            ),
            // يمكن إضافة المزيد من التفاصيل هنا
          ],
        ),
      ),
    );
  }
}
// TODO: أنشئ شاشة EditArticleScreen لتعديل بيانات المقال (ستحتاج ConsultantArticleProvider.updateArticle)