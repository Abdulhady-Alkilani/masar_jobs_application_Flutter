// lib/screens/admin/users/admin_create_edit_user_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/user.dart';
import '../../../../providers/admin_user_provider.dart';
import '../../../../services/api_service.dart';

class AdminCreateEditUserScreen extends StatefulWidget {
  final User? user; // إذا كان null، فهذا يعني إنشاء

  const AdminCreateEditUserScreen({super.key, this.user});

  @override
  State<AdminCreateEditUserScreen> createState() => _AdminCreateEditUserScreenState();
}

class _AdminCreateEditUserScreenState extends State<AdminCreateEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.user != null;
  late Map<String, dynamic> _userData;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة', 'Admin'];

  @override
  void initState() {
    super.initState();
    _userData = {
      'first_name': widget.user?.firstName ?? '',
      'last_name': widget.user?.lastName ?? '',
      'username': widget.user?.username ?? '',
      'email': widget.user?.email ?? '',
      'phone': widget.user?.phone ?? '',
      'type': widget.user?.type ?? 'خريج',
      'password': '', // كلمة المرور لا يتم جلبها
    };

    _firstNameController.text = _userData['first_name'];
    _lastNameController.text = _userData['last_name'];
    _usernameController.text = _userData['username'];
    _emailController.text = _userData['email'];
    _phoneController.text = _userData['phone'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminUserProvider>(context, listen: false);

      // إزالة كلمة المرور إذا كانت فارغة (حتى لا يتم تحديثها بقيمة فارغة)
      if (_userData['password'].isEmpty) {
        _userData.remove('password');
      }

      try {
        if (_isEditing) {
          await provider.updateUser(context, widget.user!.userId!, _userData);
        } else {
          await provider.createUser(context, _userData);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المستخدم' : 'إنشاء مستخدم جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'الاسم الأول'), onSaved: (v) => _userData['first_name'] = v!),
              TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'الاسم الأخير'), onSaved: (v) => _userData['last_name'] = v!),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'اسم المستخدم'), onSaved: (v) => _userData['username'] = v!),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress, onSaved: (v) => _userData['email'] = v!),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'الهاتف'), keyboardType: TextInputType.phone, onSaved: (v) => _userData['phone'] = v!),
              DropdownButtonFormField<String>(
                value: _userData['type'],
                decoration: const InputDecoration(labelText: 'نوع الحساب'),
                items: _userTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (v) => setState(() => _userData['type'] = v!),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'كلمة المرور', hintText: _isEditing ? 'اتركه فارغاً لعدم التغيير' : null),
                obscureText: true,
                validator: (v) {
                  if (!_isEditing && (v == null || v.isEmpty)) {
                    return 'كلمة المرور مطلوبة عند الإنشاء';
                  }
                  return null;
                },
                onSaved: (v) => _userData['password'] = v!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء المستخدم'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}