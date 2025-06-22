// lib/screens/consultant/articles/create_edit_article_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../providers/consultant_article_provider.dart';
import '../../../services/api_service.dart';

class CreateEditArticleScreen extends StatefulWidget {
  final Article? article;

  const CreateEditArticleScreen({super.key, this.article});

  @override
  State<CreateEditArticleScreen> createState() => _CreateEditArticleScreenState();
}

class _CreateEditArticleScreenState extends State<CreateEditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.article != null;
  late final Map<String, dynamic> _articleData;
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _articleData = {
      'Title': widget.article?.title ?? '',
      'Description': widget.article?.description ?? '',
    };

    _titleController.text = _articleData['Title'];
    _descriptionController.text = _articleData['Description'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final provider = Provider.of<ConsultantArticleProvider>(context, listen: false);
      try {
        if (_isEditing) {
          await provider.updateArticle(context, widget.article!.articleId!, _articleData);
        } else {
          await provider.createArticle(context, _articleData);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.message}'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المقال' : 'مقال جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TODO: إضافة حقل لاختيار صورة المقال
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade500),
                      const SizedBox(height: 8),
                      Text('إضافة صورة للمقال', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _titleController,
                label: 'عنوان المقال',
                icon: Icons.title_rounded,
                validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null,
                onSaved: (v) => _articleData['Title'] = v!,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'محتوى المقال',
                icon: Icons.article_outlined,
                maxLines: 10,
                validator: (v) => v!.isEmpty ? 'المحتوى مطلوب' : null,
                onSaved: (v) => _articleData['Description'] = v!,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(_isEditing ? Icons.save_alt_rounded : Icons.add_rounded),
                label: Text(_isEditing ? 'حفظ التعديلات' : 'نشر المقال'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}