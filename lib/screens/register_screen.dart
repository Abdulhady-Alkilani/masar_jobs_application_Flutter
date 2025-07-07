// lib/screens/auth/register_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

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
  final _passwordConfirmController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedType;
  bool _isPasswordVisible = false;

  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة'];

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.register(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _passwordConfirmController.text,
        _phoneController.text.trim(),
        _selectedType!,
      );
      // بعد النجاح، الـ Wrapper سيتولى إعادة التوجيه
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, textAlign: TextAlign.right),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFF0F4F8)),
          Positioned(top: -100, left: -120, child: _buildShape(theme.primaryColor.withOpacity(0.2), 350)),
          Positioned(bottom: -150, right: -150, child: _buildShape(theme.colorScheme.secondary.withOpacity(0.2), 400)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'إنشاء حساب جديد',
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(controller: _firstNameController, label: 'الاسم الأول', icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _lastNameController, label: 'الاسم الأخير', icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _usernameController, label: 'اسم المستخدم', icon: Icons.alternate_email),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _emailController, label: 'البريد الإلكتروني', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v != null && !v.contains('@') ? 'بريد غير صالح' : null),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            validator: (v) => v != null && v.length < 8 ? '8 أحرف على الأقل' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _passwordConfirmController, label: 'تأكيد كلمة المرور', icon: Icons.lock_person_outlined, obscureText: true, validator: (v) => v != _passwordController.text ? 'غير متطابقة' : null),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _phoneController, label: 'رقم الهاتف (اختياري)', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, isOptional: true),
                          const SizedBox(height: 16),
                          _buildDropdownField(),
                          const SizedBox(height: 32),
                          authProvider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildRegisterButton(),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('لديك حساب بالفعل؟'),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                          child: Text('سجل الدخول', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShape(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(duration: 25.seconds, begin: 0.7, end: 1.3)
        .then().rotate(duration: 40.seconds, begin: -0.1, end: 0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: validator ?? (v) {
        if (!isOptional && (v == null || v.trim().isEmpty)) {
          return 'الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'نوع الحساب',
        prefixIcon: Icon(Icons.group_outlined, color: Theme.of(context).primaryColor),
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      value: _selectedType,
      items: _userTypes.map((type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
      onChanged: (newValue) => setState(() => _selectedType = newValue),
      validator: (value) => value == null ? 'الرجاء اختيار نوع الحساب' : null,
    );
  }

  Widget _buildRegisterButton() {
    return OutlinedButton(
      onPressed: _register,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text('إنشاء الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
    );
  }
}