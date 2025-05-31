import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart'; // لتنفيذ عملية التحديث
import '../models/user.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// قد تحتاج لاستيراد Providers أخرى إذا كنت ستعدل علاقات (مثل المهارات أو الشركة) من هنا


class EditUserScreen extends StatefulWidget {
  final User user; // المستخدم الذي سيتم تعديله

  const EditUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // غالباً لا يتم تعديل كلمة المرور مباشرة في نفس نموذج تعديل باقي البيانات
  // قد يكون هناك حقل اختياري لكلمة المرور الجديدة أو شاشة منفصلة لتغيير كلمة المرور
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedType; // للتحكم في نوع المستخدم (Dropdown)
  String? _selectedStatus; // للتحكم في حالة المستخدم (Dropdown)

  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة', 'Admin']; // أنواع المستخدمين المتاحة
  final List<String> _userStatuses = ['مفعل', 'معلق', 'محذوف']; // حالات المستخدم المتاحة


  @override
  void initState() {
    super.initState();
    // تعبئة الحقول بالبيانات الحالية للمستخدم
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _usernameController.text = widget.user.username ?? '';
    _emailController.text = widget.user.email ?? '';
    _phoneController.text = widget.user.phone ?? '';
    _selectedType = widget.user.type; // تعيين القيمة الافتراضية للقائمة المنسدلة
    _selectedStatus = widget.user.status; // تعيين القيمة الافتراضية للقائمة المنسدلة

    // TODO: إذا كنت ستعدل علاقات (مثل المهارات، الشركة المرتبطة) من هذه الشاشة، قم بجلب البيانات اللازمة هنا
  }


  // تابع لحفظ التعديلات
  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminUserProvider>(context, listen: false);

      final userData = {
        // لا ترسل UserID في body للتعديل، هو جزء من URL
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        // 'password': ..., // لا ترسل كلمة المرور من هنا غالباً
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text, // إرسال null إذا كان فارغاً
        'type': _selectedType, // القيمة المختارة
        'status': _selectedStatus, // القيمة المختارة
        // 'email_verified': true/false based on a Checkbox/Switch
        // 'photo': ..., // معالجة تعديل الصورة
      };

      try {
        await provider.updateUser(context, widget.user.userId!, userData); // استدعاء تابع التحديث

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المستخدم بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة تفاصيل المستخدم
        Navigator.pop(context);

      } catch (e) {
        String errorMessage = 'فشل التحديث: ${e.toString()}';
        if (e is ApiException && e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors); // يمكنك معالجة أخطاء التحقق بشكل أفضل
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
    _phoneController.dispose();
    // لا تنسى dispose للـ controllers الأخرى إذا أضفتها
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminUserProvider>(context); // للاستماع لحالة التحميل عند الحفظ

    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل المستخدم: ${widget.user.username ?? ''}'),
      ),
      body: provider.isLoading // إذا كان Provider يحمل بيانات (عند الحفظ)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // حقول بيانات المستخدم الأساسية
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
                  // TODO: تحقق من عدم تكرار اسم المستخدم (باستثناء المستخدم الحالي)
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
                  // TODO: تحقق من تنسيق البريد الإلكتروني وعدم تكراره (باستثناء المستخدم الحالي)
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                // لا حاجة لـ validator إذا كان اختياري، أو تحقق من التنسيق إذا أدخل شيء
              ),
              const SizedBox(height: 12.0),
              // قائمة منسدلة لنوع الحساب
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
              const SizedBox(height: 12.0),
              // قائمة منسدلة لحالة الحساب
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'حالة الحساب'),
                value: _selectedStatus,
                items: _userStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'الرجاء اختيار حالة الحساب';
                  }
                  return null;
                },
              ),
              // TODO: إضافة حقل لتعديل email_verified (Checkbox/Switch)
              // TODO: إضافة خيار لتعديل كلمة المرور (ربما زر يفتح AlertDialog لطلب كلمة مرور جديدة وتأكيدها)
              // TODO: إضافة خيار لتعديل الصورة (Image Picker)
              // TODO: إضافة خيارات لتعديل العلاقات (الملف الشخصي، المهارات، الشركة المرتبطة)

              const SizedBox(height: 24.0),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveUser, // تعطيل الزر أثناء التحميل
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}