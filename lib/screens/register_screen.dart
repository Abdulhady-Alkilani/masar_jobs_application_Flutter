import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../widgets/rive_loading_indicator.dart';
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
  bool _isButtonEnabled = false;

  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة'];

  @override
  void initState() {
    super.initState();
    final controllers = [
      _firstNameController,
      _lastNameController,
      _usernameController,
      _emailController,
      _passwordController,
      _passwordConfirmController,
    ];
    for (var controller in controllers) {
      controller.addListener(_validateForm);
    }
  }

  @override
  void dispose() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _usernameController,
      _emailController,
      _passwordController,
      _passwordConfirmController,
      _phoneController,
    ];
    for (var controller in controllers) {
      controller.removeListener(_validateForm);
      controller.dispose();
    }
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _passwordConfirmController.text.isNotEmpty &&
          _selectedType != null;
    });
  }

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
      // After success, the Wrapper will handle redirection
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFF0F4F8)),
          Positioned(
              top: -150,
              right: -150,
              child: _buildShape(theme.primaryColor.withOpacity(0.2), 300)),
          Positioned(
              bottom: -180,
              left: -100,
              child: _buildShape(
                  theme.colorScheme.secondary.withOpacity(0.2), 400)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/image/ChatGPT Image Apr 17, 2025, 11_34_59 PM.png',
                      height: 100,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'حساب جديد',
                      style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                              controller: _firstNameController,
                              label: 'الاسم الأول',
                              icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _lastNameController,
                              label: 'الاسم الأخير',
                              icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _usernameController,
                              label: 'اسم المستخدم',
                              icon: Icons.alternate_email),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _emailController,
                              label: 'البريد الإلكتروني',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v != null && !v.contains('@') ? 'بريد غير صالح' : null),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            validator: (v) =>
                                v != null && v.length < 8 ? '8 أحرف على الأقل' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _passwordConfirmController,
                              label: 'تأكيد كلمة المرور',
                              icon: Icons.lock_person_outlined,
                              obscureText: true,
                              validator: (v) =>
                                  v != _passwordController.text ? 'غير متطابقة' : null),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _phoneController,
                              label: 'رقم الهاتف (اختياري)',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => null), // Optional field
                          const SizedBox(height: 16),
                          _buildDropdownField(),
                          const SizedBox(height: 32),
                          authProvider.isLoading
                              ? const Center(child: RiveLoadingIndicator())
                              : _buildRegisterButton(context),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('لديك حساب بالفعل؟'),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
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
        ],
      ),
    );
  }

  Widget _buildShape(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(duration: 25.seconds, begin: 0.7, end: 1.3)
        .then()
        .rotate(duration: 40.seconds, begin: -0.1, end: 0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'نوع الحساب',
        prefixIcon: Icon(Icons.group_outlined, color: Theme.of(context).primaryColor),
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
      value: _selectedType,
      items: _userTypes
          .map((type) => DropdownMenuItem<String>(
              value: type, child: Text(type)))
          .toList(),
      onChanged: (newValue) {
        setState(() => _selectedType = newValue);
        _validateForm();
      },
      validator: (value) =>
          value == null ? 'الرجاء اختيار نوع الحساب' : null,
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isButtonEnabled
              ? [theme.primaryColor, theme.colorScheme.secondary]
              : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: _isButtonEnabled
            ? [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isButtonEnabled ? _register : null,
          borderRadius: BorderRadius.circular(15),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'إنشاء الحساب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}