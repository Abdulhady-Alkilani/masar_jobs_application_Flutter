// lib/screens/consultant/articles/create_edit_article_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/article.dart';
import '../../../providers/consultant_article_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

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

  File? _selectedImage;
  PlatformFile? _selectedPdf;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() => _selectedPdf = result.files.first);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _articleData['Date'] = currentDate;

      // TODO: Add logic to upload files and get URLs
      // _articleData['Article Photo'] = 'url_of_uploaded_image';
      // _articleData['PdfLink'] = 'url_of_uploaded_pdf';

      final provider = Provider.of<ConsultantArticleProvider>(context, listen: false);
      try {
        if (_isEditing) {
          await provider.updateArticle(context, widget.article!.articleId!, _articleData);
        }
        else {
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'تعديل المقال' : 'مقال جديد'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(theme),
              const SizedBox(height: 32),
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
                maxLines: 8,
                validator: (v) => v!.isEmpty ? 'المحتوى مطلوب' : null,
                onSaved: (v) => _articleData['Description'] = v!,
              ),
              const SizedBox(height: 24),
              _buildPdfPicker(theme),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: RiveLoadingIndicator()) // Replaced here
                  : ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(_isEditing ? Icons.save_alt_rounded : Icons.publish_rounded),
                label: Text(_isEditing ? 'حفظ التعديلات' : 'نشر المقال'),
                style: theme.elevatedButtonTheme.style,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- دوال مساعدة معبأة بالكامل ---

  Widget _buildImagePicker(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: _selectedImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text('اختر صورة رئيسية للمقال', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPicker(ThemeData theme) {
    return ListTile(
      onTap: _pickPdf,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      tileColor: theme.primaryColor.withOpacity(0.05),
      leading: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.error, size: 30),
      title: Text(
        _selectedPdf == null ? 'إرفاق ملف PDF (اختياري)' : 'الملف المرفق:',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _selectedPdf != null ? Text(_selectedPdf!.name, overflow: TextOverflow.ellipsis) : null,
      trailing: _selectedPdf != null
          ? IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.grey),
        onPressed: () => setState(() => _selectedPdf = null),
      )
          : const Icon(Icons.attach_file_rounded, color: Colors.grey),
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
        fillColor: Theme.of(context).primaryColor.withOpacity(0.02),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}