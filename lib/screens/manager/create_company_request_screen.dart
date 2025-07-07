// lib/screens/manager/create_company_request_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/managed_company_provider.dart';
import '../../services/api_service.dart';

class CreateCompanyRequestScreen extends StatefulWidget {
  const CreateCompanyRequestScreen({super.key});

  @override
  State<CreateCompanyRequestScreen> createState() => _CreateCompanyRequestScreenState();
}

class _CreateCompanyRequestScreenState extends State<CreateCompanyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _companyData = {
    'Name': '',
    'Email': '',
    'Phone': '',
    'Description': '',
    'Country': '',
    'City': '',
    'Detailed Address': '',
    'Web site': '',
  };

  // --- دالة إرسال الطلب (كاملة وصحيحة) ---
  Future<void> _submitRequest() async {
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // التحقق من صحة كل الحقول
    if (!_formKey.currentState!.validate()) {
      // إذا كان هناك حقل غير صالح، لا تكمل العملية
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة كل الحقول المطلوبة بشكل صحيح.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // حفظ البيانات من الحقول إلى الخريطة
    _formKey.currentState!.save();

    // الوصول إلى الـ Provider
    final provider = Provider.of<ManagedCompanyProvider>(context, listen: false);

    try {
      // استدعاء دالة إنشاء الشركة في الـ Provider
      await provider.createManagedCompany(context, _companyData);

      // في حالة النجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلبك بنجاح وسيتم مراجعته.'),
            backgroundColor: Colors.green,
          ),
        );
        // العودة إلى الشاشة السابقة بعد نجاح الطلب
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      // في حالة فشل الـ API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الطلب: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ManagedCompanyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب إنشاء ملف شركة'),
      ),
      // زر الإرسال في الأسفل ليكون دائمًا ظاهرًا
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          onPressed: _submitRequest,
          icon: const Icon(Icons.send_rounded),
          label: const Text('إرسال الطلب للمراجعة'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- قسم المعلومات الأساسية ---
              _buildSectionTitle(theme, 'المعلومات الأساسية'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildTextFormField(label: 'اسم الشركة', icon: Icons.business, onSaved: (v) => _companyData['Name'] = v!),
                      _buildTextFormField(label: 'وصف الشركة', icon: Icons.description_outlined, maxLines: 4, onSaved: (v) => _companyData['Description'] = v!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- قسم معلومات التواصل ---
              _buildSectionTitle(theme, 'معلومات التواصل'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildTextFormField(label: 'البريد الإلكتروني الرسمي', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, onSaved: (v) => _companyData['Email'] = v!),
                      _buildTextFormField(label: 'هاتف الشركة', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, onSaved: (v) => _companyData['Phone'] = v!),
                      _buildTextFormField(label: 'الموقع الإلكتروني (اختياري)', icon: Icons.public, isOptional: true, keyboardType: TextInputType.url, onSaved: (v) => _companyData['Web site'] = v!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- قسم العنوان ---
              _buildSectionTitle(theme, 'العنوان'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildTextFormField(label: 'الدولة', icon: Icons.flag_outlined, onSaved: (v) => _companyData['Country'] = v!),
                      _buildTextFormField(label: 'المدينة', icon: Icons.location_city_outlined, onSaved: (v) => _companyData['City'] = v!),
                      _buildTextFormField(label: 'العنوان التفصيلي', icon: Icons.location_on_outlined, maxLines: 2, onSaved: (v) => _companyData['Detailed Address'] = v!),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }

  // --- دوال مساعدة للتصميم ---
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12.0),
      child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isOptional = false,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: TextFormField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (!isOptional && (value == null || value.trim().isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (label.contains('البريد الإلكتروني') && value != null && !value.contains('@')) {
            return 'صيغة البريد الإلكتروني غير صحيحة';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }
}