// lib/screens/consultant/articles/managed_articles_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/consultant_article_provider.dart';
import '../../../models/article.dart';
import '../../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_edit_article_screen.dart';

class ManagedArticlesListScreen extends StatefulWidget {
  const ManagedArticlesListScreen({super.key});
  @override
  State<ManagedArticlesListScreen> createState() => _ManagedArticlesListScreenState();
}

class _ManagedArticlesListScreenState extends State<ManagedArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ConsultantArticleProvider>(context, listen: false);
    provider.fetchManagedArticles(context);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreManagedArticles(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteArticle(Article article, ConsultantArticleProvider provider) async {
    // ... منطق الحذف
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مقالاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة مقال جديد',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditArticleScreen()));
            },
          ),
        ],
      ),
      body: Consumer<ConsultantArticleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.managedArticles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.managedArticles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'حدث خطأ',
              message: 'لم نتمكن من جلب مقالاتك. حاول تحديث الصفحة.',
              onRefresh: () => provider.fetchManagedArticles(context),
            );
          }
          if (provider.managedArticles.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'ابدأ بالكتابة!',
              message: 'لم تقم بنشر أي مقالات بعد. اضغط على زر الإضافة لمشاركة معرفتك.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchManagedArticles(context),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.managedArticles.length + (provider.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.managedArticles.length) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                final article = provider.managedArticles[index];
                return _buildArticleCard(article, provider)
                    .animate(delay: (100 * (index % 10)).ms)
                    .fadeIn()
                    .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(Article article, ConsultantArticleProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.article_outlined, color: Theme.of(context).primaryColor),
        ),
        title: Text(article.title ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('تاريخ النشر: ${article.date?.toLocal().toString().substring(0, 10) ?? 'غير معروف'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditArticleScreen(article: article)));
            } else if (value == 'delete') {
              _deleteArticle(article, provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}