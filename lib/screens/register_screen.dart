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
        backgroundColor: Theme.of(context).colorScheme.error,
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
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'إنشاء حساب جديد',
                  style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                              labelText: 'الاسم الأول',
                              prefixIcon: Icon(Icons.person_outline))),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                              labelText: 'الاسم الأخير',
                              prefixIcon: Icon(Icons.person_outline))),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                              labelText: 'اسم المستخدم',
                              prefixIcon: Icon(Icons.alternate_email))),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined)),
                          validator: (v) =>
                              v != null && !v.contains('@') ? 'بريد غير صالح' : null),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (v) =>
                            v != null && v.length < 8 ? '8 أحرف على الأقل' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _passwordConfirmController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              prefixIcon: Icon(Icons.lock_person_outlined)),
                          validator: (v) =>
                              v != _passwordController.text ? 'غير متطابقة' : null),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'رقم الهاتف (اختياري)',
                              prefixIcon: Icon(Icons.phone_outlined))),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'نوع الحساب',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        value: _selectedType,
                        items: _userTypes
                            .map((type) => DropdownMenuItem<String>(
                                value: type, child: Text(type)))
                            .toList(),
                        onChanged: (newValue) =>
                            setState(() => _selectedType = newValue),
                        validator: (value) =>
                            value == null ? 'الرجاء اختيار نوع الحساب' : null,
                      ),
                      const SizedBox(height: 32),
                      authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _register,
                              child: const Text('إنشاء الحساب'),
                            ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟'),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Text('سجل الدخول',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
