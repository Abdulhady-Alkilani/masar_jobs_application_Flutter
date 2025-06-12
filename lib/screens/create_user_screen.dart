import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart'; // لتنفيذ عملية الإنشاء
import '../services/api_service.dart'; // لاستخدام ApiException
import 'package:image_picker/image_picker.dart'; // <--- استيراد حزمة اختيار الصور
import 'dart:io'; // لاستخدام File

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // اختياري

  // حقول Dropdown أو TextFields لقيم محددة
  String? _selectedType; // نوع المستخدم
  String? _selectedStatus; // حالة المستخدم

  // حقل Checkbox
  bool _emailVerified = false; // حالة تفعيل البريد الإلكتروني

  // حقل الصورة
  File? _pickedImage; // ملف الصورة الذي تم اختياره

  // TODO: قائمة أنواع المستخدمين المتاحة (يجب أن تأتي من Backend أو ثابت هنا)
  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة', 'Admin'];
  // TODO: قائمة حالات المستخدمين المتاحة (يجب أن تأتي من Backend أو ثابت هنا)
  final List<String> _userStatuses = ['مفعل', 'معلق', 'محذوف'];


  @override
  void initState() {
    super.initState();
    // تعيين قيم افتراضية للحقول الجديدة
    _selectedType = _userTypes.isNotEmpty ? _userTypes.first : null; // تعيين أول نوع كافتراضي
    _selectedStatus = _userStatuses.isNotEmpty ? _userStatuses.first : null; // تعيين أول حالة كافتراضي
  }

  // تابع لاختيار صورة الملف الشخصي
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // يمكن تغيير source إلى ImageSource.camera

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }


  // تابع لإنشاء مستخدم جديد
  Future<void> _createUser() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminUserProvider>(context, listen: false);

      // بيانات المستخدم المراد إرسالها
      final userData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmationController.text, // يجب أن يطلب API هذا غالباً عند الإنشاء
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text, // إرسال null إذا كان فارغاً
        'type': _selectedType, // القيمة المختارة من Dropdown
        'status': _selectedStatus, // القيمة المختارة من Dropdown
        'email_verified': _emailVerified, // قيمة Checkbox
        // 'photo': ... // معالجة رفع ملف الصورة هنا
      };

      try {
        // عملية إنشاء
        // TODO: تعديل ApiService.createNewUser ليقبل ملف الصورة ويرسله كـ multipart/form-data
        // هذا يتطلب تغيير طريقة إرسال الطلب في ApiService من jsonEncode إلى FormData أو MultipartRequest
        // وهذا تغيير كبير في ApiService!

        // For now, we will call the API without the photo or assume photo is sent as path string (less likely)
        await provider.createUser(context, userData); // استدعاء تابع الإنشاء (بدون صورة حالياً)

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المستخدم بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة قائمة المستخدمين
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل الإنشاء: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية في الفورم
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإنشاء: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    // لا تنسى dispose لجميع حقول التحكم بالنصوص
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _phoneController.dispose();
    // لا نحتاج dispose للـ dropdown/checkbox state
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من AdminUserProvider عند الحفظ
    final provider = Provider.of<AdminUserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مستخدم جديد'), // دائماً شاشة إضافة
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
                  // TODO: تحقق من عدم تكرار اسم المستخدم (يتم التحقق في Backend أيضاً)
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
                  // TODO: تحقق من تنسيق البريد الإلكتروني وعدم تكراره (يتم التحقق في Backend أيضاً)
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
              Row( // استخدام Row لعرض Checkbox والنص
                children: [
                  Checkbox(
                    value: _emailVerified,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _emailVerified = newValue;
                        });
                      }
                    },
                  ),
                  const Text('تفعيل البريد الإلكتروني'), // نص Checkbox
                ],
              ),
              const SizedBox(height: 12.0),
              // TODO: إضافة خيار لرفع الصورة (Image Picker)
              const Text('صورة الملف الشخصي (اختياري):'),
              const SizedBox(height: 8.0),
              ElevatedButton.icon(
                onPressed: _pickImage, // استدعاء تابع اختيار الصورة
                icon: const Icon(Icons.photo_library),
                label: const Text('اختيار صورة من المعرض'), // يمكن إضافة خيار للكاميرا أيضاً
              ),
              // عرض الصورة المختارة
              if (_pickedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(
                    _pickedImage!,
                    height: 100, // ارتفاع افتراضي
                    width: 100, // عرض افتراضي
                    fit: BoxFit.cover,
                  ),
                ),


              const SizedBox(height: 24.0),
              // زر الحفظ (الإنشاء)
              ElevatedButton(
                onPressed: provider.isLoading ? null : _createUser, // تعطيل الزر أثناء التحميل
                child: const Text('إنشاء المستخدم'), // دائماً نص إنشاء
              ),
            ],
          ),
        ),
      ),
    );
  }
}