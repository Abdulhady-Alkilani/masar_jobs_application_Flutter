import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart'; // لاستخدام ApiException

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedType; // للتحكم في نوع المستخدم (dropdown)

  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة']; // أنواع المستخدمين المتاحة للتسجيل

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // تأكد من اختيار نوع المستخدم
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار نوع الحساب.')),
        );
        return; // إيقاف العملية إذا لم يتم الاختيار
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.register(
          _firstNameController.text,
          _lastNameController.text,
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _passwordConfirmationController.text,
          _phoneController.text,
          _selectedType!, // استخدم القيمة المختارة
        );

        // إذا نجح التسجيل، Provider سيغير الحالة وWrapperScreen سيعيد التوجيه
        // يمكن أيضاً عرض رسالة نجاح هنا
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب بنجاح!')),
        );


      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: ${e.message}')),
        );
        if (e.errors != null) {
          // عرض أخطاء التحقق
          e.errors!.forEach((field, messages) {
            print('$field: ${messages.join(", ")}');
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
        print('Unexpected registration error: $e');
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

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الأول'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الأول';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الأخير'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الأخير';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم المستخدم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    // تحقق من تنسيق البريد الإلكتروني
                    if (!value.contains('@')) {
                      return 'الرجاء إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    // يمكنك إضافة متطلبات تعقيد لكلمة المرور هنا
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _passwordConfirmationController,
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                  keyboardType: TextInputType.phone,
                  // رقم الهاتف ليس مطلوباً في API، لذا لا حاجة لـ validator هنا إلا إذا أردت التحقق من التنسيق عند إدخاله
                ),
                const SizedBox(height: 12.0),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  value: _selectedType,
                  items: _userTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'الرجاء اختيار نوع الحساب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                authProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _register,
                  child: const Text('إنشاء الحساب'),
                ),
                const SizedBox(height: 12.0),
                TextButton(
                  onPressed: () {
                    // العودة إلى شاشة تسجيل الدخول
                    Navigator.pop(context);
                  },
                  child: const Text('تمتلك حساب بالفعل؟ سجل دخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}