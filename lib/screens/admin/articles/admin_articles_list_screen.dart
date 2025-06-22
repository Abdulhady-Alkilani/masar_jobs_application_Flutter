// lib/screens/admin/articles/admin_articles_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../../providers/admin_article_provider.dart';
import '../../../models/article.dart';
// TODO: قم باستيراد شاشة تفاصيل المقال للأدمن وشاشة إضافة/تعديل المقال
import 'admin_article_details_screen.dart';
import 'admin_create_edit_article_screen.dart';


class AdminArticlesListScreen extends StatefulWidget {
  const AdminArticlesListScreen({super.key});

  @override
  State<AdminArticlesListScreen> createState() => _AdminArticlesListScreenState();
}

class _AdminArticlesListScreenState extends State<AdminArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // جلب الصفحة الأولى عند تهيئة الشاشة لأول مرة
    // نستخدم listen: false لأننا لا نبني واجهة داخل initState
    final provider = Provider.of<AdminArticleProvider>(context, listen: false);

    // تأكد من أن القائمة فارغة قبل الجلب لتجنب تراكم البيانات
    // أو يمكنك إضافة منطق لتحديد متى يجب إعادة الجلب بالكامل
    if (provider.articles.isEmpty) {
      provider.fetchAllArticles(context);
    }

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق مما إذا كان المستخدم قد وصل إلى نهاية القائمة تقريباً
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95) {
        // تحقق مما إذا كان هناك المزيد من الصفحات للجلب وأننا لا نجلب حالياً
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreArticles(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // تنظيف الـ controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم Consumer للاستماع إلى تغييرات AdminArticleProvider وإعادة بناء الواجهة
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المقالات (أدمن)'),
      ),
      body: Consumer<AdminArticleProvider>(
        builder: (context, provider, child) {
          // عرض مؤشر تحميل إذا كانت القائمة فارغة ويتم تحميلها لأول مرة
          if (provider.isLoading && provider.articles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // عرض رسالة خطأ إذا حدث خطأ والقائمة فارغة
          if (provider.error != null && provider.articles.isEmpty) {
            return Center(child: Text('حدث خطأ: ${provider.error}'));
          }

          // عرض رسالة إذا كانت القائمة فارغة بعد التحميل
          if (provider.articles.isEmpty) {
            return const Center(child: Text('لا توجد مقالات متاحة للإدارة حالياً.'));
          }

          // عرض القائمة مع إمكانية السحب للتحديث
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllArticles(context), // عند السحب للأسفل، قم بجلب الصفحة الأولى مجدداً
            child: ListView.builder(
              controller: _scrollController, // ربط الـ controller بالتمرير
              itemCount: provider.articles.length + (provider.isFetchingMore ? 1 : 0), // +1 لعرض مؤشر التحميل في نهاية القائمة
              itemBuilder: (context, index) {
                // إذا وصلنا إلى العنصر الأخير وكان هناك جلب للمزيد، اعرض مؤشر التحميل
                if (index == provider.articles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // عرض بطاقة المقال
                final article = provider.articles[index];
                return _buildArticleCard(context, article, provider);
              },
            ),
          );
        },
      ),
      // زر عائم لإضافة مقال جديد
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: الانتقال إلى شاشة إضافة مقال جديد
           Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEditArticleScreen()));
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة مقال جديد',
      ),
    );
  }

  // بناء بطاقة عرض المقال
  Widget _buildArticleCard(BuildContext context, Article article, AdminArticleProvider provider) {
    // !!! استبدل هذا الرابط بعنوان موقعك الأساسي إذا لم يكن موجوداً في ApiService أو مكان عام !!!
    // يمكنك أيضاً إضافة baseUrl كـ static const في ApiService أو Util Class
    const String baseUrl = 'https://powderblue-woodpecker-887296.hostingersite.com';
    final imageUrl = (article.articlePhoto != null && article.articlePhoto!.isNotEmpty)
        ? baseUrl + article.articlePhoto!
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // TODO: الانتقال إلى شاشة تفاصيل المقال للأدمن (قد تسمح بالتعديل المباشر)
           Navigator.push(context, MaterialPageRoute(builder: (context) => AdminArticleDetailsScreen(articleId: article.articleId!)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المقال
            if (imageUrl != null)
              Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
              ),

            // محتوى البطاقة
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title ?? 'بدون عنوان',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      // كاتب المقال (يجب أن يكون الأدمن أو الاستشاري الذي أنشأه)
                      if (article.user != null) ...[
                        CircleAvatar(
                          radius: 15,
                          // backgroundImage: NetworkImage(...) إذا كان للمستخدم صورة
                          child: Text(article.user!.firstName?.substring(0,1) ?? '?'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${article.user!.firstName} ${article.user!.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                      const Spacer(),
                      // تاريخ النشر
                      if (article.date != null)
                        Text(
                          DateFormat.yMMMd('ar').format(article.date!), // تنسيق عربي للتاريخ
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // أزرار التعديل والحذف
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'تعديل',
                        onPressed: () {
                          // TODO: الانتقال إلى شاشة تعديل المقال
                           Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCreateEditArticleScreen(article: article)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'حذف',
                        onPressed: () async {
                          // تأكيد الحذف قبل المتابعة
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

                          if (confirmDelete == true && article.articleId != null) {
                            try {
                              // استدعاء تابع الحذف من Provider
                              await provider.deleteArticle(context, article.articleId!);
                              // عرض رسالة نجاح (اختياري)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم حذف المقال بنجاح')),
                              );
                            } catch (e) {
                              // التعامل مع الخطأ إذا لم يتمكن Provider من الحذف
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل حذف المقال: ${provider.error}')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// يمكنك إبقاء هذا الـ Extension هنا أو نقله إلى ملف Extensions مشترك
extension ListArticleExtension on List<Article> {
  Article? firstWhereOrNull(bool Function(Article) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}