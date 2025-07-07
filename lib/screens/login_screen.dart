// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.login(_emailController.text.trim(), _passwordController.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, textAlign: TextAlign.right),
        backgroundColor: Colors.red.shade400,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. الخلفية الهندسية المتحركة ---
          Container(color: const Color(0xFFF0F4F8)),
          Positioned(top: -150, right: -150, child: _buildShape(theme.primaryColor.withOpacity(0.2), 300)),
          Positioned(bottom: -180, left: -100, child: _buildShape(theme.colorScheme.secondary.withOpacity(0.2), 400)),

          // --- 2. المحتوى ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'أهلاً بك',
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    const Text('ابدأ رحلتك المهنية مع مسار', style: TextStyle(fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 50),

                    // --- 3. النموذج الشفاف ---
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            icon: Icons.alternate_email,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          const SizedBox(height: 40),
                          authProvider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildLoginButton(context),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ليس لديك حساب ؟'),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text('سجل الان', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
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

  // --- دوال مساعدة محدثة ---

  Widget _buildShape(Color color, double size) {
    return Container(
      width: size,
      height: size,
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        // تصميم شفاف
        filled: true,
        fillColor: Colors.black.withOpacity(0.04), // لون خفيف جداً
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return OutlinedButton( // <-- استخدام OutlinedButton
      onPressed: _login,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 2), // إطار بلون الثيم
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),

      child: Text(
        'تسجيل الدخول',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      ),

    );
  }
}