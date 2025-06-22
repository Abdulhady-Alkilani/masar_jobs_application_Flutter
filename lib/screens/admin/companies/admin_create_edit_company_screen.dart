// lib/screens/admin/companies/admin_create_edit_company_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/company.dart';
import '../../../models/user.dart'; // نحتاج موديل المستخدم لعرض قائمة المدراء
import '../../../providers/admin_company_provider.dart';
import '../../../providers/admin_user_provider.dart'; // لجلب قائمة المستخدمين (المدراء)
import '../../../services/api_service.dart';

class AdminCreateEditCompanyScreen extends StatefulWidget {
  final Company? company; // إذا كان null، فهذا يعني إنشاء جديد

  const AdminCreateEditCompanyScreen({super.key, this.company});

  @override
  State<AdminCreateEditCompanyScreen> createState() => _AdminCreateEditCompanyScreenState();
}

class _AdminCreateEditCompanyScreenState extends State<AdminCreateEditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.company != null;
  late Map<String, dynamic> _companyData;
  bool _isLoadingUsers = true;

  // قائمة المستخدمين من نوع "مدير شركة" للاختيار منها
  List<User> _companyManagers = [];

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  // ... يمكنك إضافة باقي الـ Controllers إذا أردت

  @override
  void initState() {
    super.initState();
    // تهيئة بيانات الشركة
    _companyData = {
      'Name': widget.company?.name ?? '',
      'Email': widget.company?.email ?? '',
      'Phone': widget.company?.phone ?? '',
      'Description': widget.company?.description ?? '',
      'Country': widget.company?.country ?? '',
      'City': widget.company?.city ?? '',
      'Detailed Address': widget.company?.detailedAddress ?? '',
      'Web site': widget.company?.webSite ?? '',
      'status': widget.company?.status ?? 'approved', // الأدمن ينشئها معتمدة غالبًا
      'UserID': widget.company?.userId, // ID المدير المسؤول
    };

    // تهيئة الـ Controllers
    _nameController.text = _companyData['Name'];
    _emailController.text = _companyData['Email'];
    _phoneController.text = _companyData['Phone'];
    _descriptionController.text = _companyData['Description'];

    // جلب قائمة المدراء
    _fetchCompanyManagers();
  }

  // دالة لجلب المستخدمين الذين نوعهم "مدير شركة"
  Future<void> _fetchCompanyManagers() async {
    // استخدم provider المستخدمين لجلبهم
    // ملاحظة: هذا يجلب جميع المستخدمين، يجب فلترتهم
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);
    await userProvider.fetchAllUsers(context); // قد تحتاج لتعديل هذا ليجلب كل الصفحات أو إضافة فلتر في API

    if (mounted) {
      setState(() {
        _companyManagers = userProvider.users.where((user) => user.type == 'مدير شركة').toList();
        _isLoadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // التأكد من اختيار مدير للشركة
      if (_companyData['UserID'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار مدير مسؤول للشركة'), backgroundColor: Colors.orange),
        );
        return;
      }

      _formKey.currentState!.save();

      final provider = Provider.of<AdminCompanyProvider>(context, listen: false);

      try {
        if (_isEditing) {
          await provider.updateCompany(context, widget.company!.companyId!, _companyData);
        } else {
          await provider.createCompany(context, _companyData);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت العملية بنجاح'), backgroundColor: Colors.green),
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
        title: Text(_isEditing ? 'تعديل الشركة' : 'إنشاء شركة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('بيانات الشركة'),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الشركة'), validator: (v) => v!.isEmpty ? 'مطلوب' : null, onSaved: (v) => _companyData['Name'] = v!),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress, onSaved: (v) => _companyData['Email'] = v!),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'الهاتف'), keyboardType: TextInputType.phone, onSaved: (v) => _companyData['Phone'] = v!),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 3, onSaved: (v) => _companyData['Description'] = v!),
              // ... يمكنك إضافة باقي الحقول هنا بنفس الطريقة ...

              const Divider(height: 32),
              _buildSectionTitle('البيانات الإدارية'),

              // قائمة منسدلة لاختيار المدير المسؤول
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                value: _companyData['UserID'],
                hint: const Text('اختر المدير المسؤول'),
                decoration: const InputDecoration(labelText: 'المدير المسؤول'),
                items: _companyManagers.map((User user) {
                  return DropdownMenuItem<int>(
                    value: user.userId,
                    child: Text('${user.firstName} ${user.lastName}'),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _companyData['UserID'] = newValue;
                  });
                },
                validator: (value) => value == null ? 'يجب اختيار مدير' : null,
              ),

              const SizedBox(height: 16),
              // قائمة منسدلة لتحديد حالة الشركة
              DropdownButtonFormField<String>(
                value: _companyData['status'],
                decoration: const InputDecoration(labelText: 'حالة الشركة'),
                items: ['approved', 'pending', 'rejected'].map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _companyData['status'] = newValue;
                  });
                },
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء الشركة'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor),
      ),
    );
  }
}