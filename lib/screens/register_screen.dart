// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedType;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة'];

  void _register() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.register(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _passwordConfirmationController.text,
          _phoneController.text.trim(),
          _selectedType!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! جارِ تسجيل الدخول...'),
              backgroundColor: Colors.green,
            ),
          );
          // الـ Wrapper سيتولى إعادة التوجيه
        }
      } on ApiException catch (e) {
        String errorMessage = e.message;
        if (e.errors != null) {
          // عرض أول خطأ من قائمة الأخطاء ليكون أوضح
          errorMessage += '\n${e.errors!.entries.first.value.first}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, textAlign: TextAlign.right),
            backgroundColor: Colors.redAccent,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. العنوان الرئيسي
                  Text(
                    'إنشاء حساب جديد',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'املأ البيانات التالية للانضمام إلينا',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // 2. حقول المعلومات الشخصية
                  _buildSectionTitle(theme, 'المعلومات الشخصية'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _firstNameController,
                          labelText: 'الاسم الأول',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _lastNameController,
                          labelText: 'الاسم الأخير',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _phoneController,
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isOptional: true, // اختياري
                  ),
                  const SizedBox(height: 32),

                  // 3. معلومات الحساب
                  _buildSectionTitle(theme, 'معلومات الحساب'),
                  _buildTextFormField(
                    controller: _usernameController,
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                      controller: _emailController,
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'الحقل مطلوب';
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'صيغة البريد الإلكتروني غير صحيحة';
                        return null;
                      }
                  ),
                  const SizedBox(height: 16),

                  // 4. كلمة المرور
                  _buildTextFormField(
                    controller: _passwordController,
                    labelText: 'كلمة المرور',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'الحقل مطلوب';
                      if (value.length < 8) return 'يجب أن تكون 8 أحرف على الأقل';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _passwordConfirmationController,
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icons.lock_person_outlined,
                    obscureText: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. نوع الحساب
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'أرغب بالتسجيل كـ',
                      prefixIcon: Icon(Icons.group_outlined, color: theme.colorScheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _selectedType,
                    items: _userTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
                    onChanged: (newValue) => setState(() => _selectedType = newValue),
                    validator: (value) => value == null ? 'الرجاء اختيار نوع الحساب' : null,
                  ),
                  const SizedBox(height: 32),

                  // 6. زر إنشاء الحساب
                  authProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إنشاء الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),

                  // 7. رابط العودة لتسجيل الدخول
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب بالفعل؟'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('سجل الدخول', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء حقول الإدخال لتجنب تكرار الكود
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Theme.of(context).colorScheme.primary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator ?? (value) {
        if (!isOptional && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  // دالة مساعدة لبناء عناوين الأقسام
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}