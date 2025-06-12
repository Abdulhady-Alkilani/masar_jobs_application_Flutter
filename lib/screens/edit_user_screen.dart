import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart'; // لتنفيذ عملية التحديث
import '../models/user.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
import 'package:image_picker/image_picker.dart'; // <--- استيراد حزمة اختيار الصور
import 'dart:io'; // لاستخدام File


class EditUserScreen extends StatefulWidget {
  final User user; // المستخدم الذي سيتم تعديله

  const EditUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص لبيانات المستخدم الأساسية التي يمكن تعديلها
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // غالباً لا يتم تعديل كلمة المرور مباشرة في نفس نموذج تعديل باقي البيانات
  // قد يكون هناك حقل اختياري لكلمة المرور الجديدة أو شاشة منفصلة لتغيير كلمة المرور
  final TextEditingController _phoneController = TextEditingController();

  // حالة تفعيل البريد الإلكتروني (Checkbox)
  bool _emailVerified = false;

  // حقول Dropdown لقيم محددة
  String? _selectedType; // نوع المستخدم
  String? _selectedStatus; // حالة المستخدم

  // حقل الصورة
  File? _pickedImage; // ملف الصورة الذي تم اختياره (لتحميل جديد)
  // يمكن تخزين URL الصورة الحالي للعرض إذا لزم الأمر

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
    _emailVerified = widget.user.emailVerified ?? false; // تعبئة حالة الـ Checkbox
    _selectedType = widget.user.type; // تعيين القيمة الافتراضية للقائمة المنسدلة
    _selectedStatus = widget.user.status; // تعيين القيمة الافتراضية للقائمة المنسدلة

    // TODO: إذا كنت ستعدل علاقات (مثل المهارات، الشركة المرتبطة) من هذه الشاشة، قم بجلب البيانات اللازمة هنا
    // أو قم بإنشاء أزرار للانتقال لشاشات تعديل العلاقات المنفصلة (مثل EditUserProfileScreen, EditUserSkillsScreen, etc.)
  }

  // تابع لاختيار صورة الملف الشخصي
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // يمكن تغيير source إلى ImageSource.camera

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        // TODO: عرض معاينة للصورة المختارة
      });
    }
  }

  // تابع لحفظ التعديلات
  Future<void> _saveUser() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminUserProvider>(context, listen: false);

      // بيانات المستخدم المراد إرسالها للتحديث
      final userData = {
        // لا ترسل UserID في body للتعديل، هو جزء من URL
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        // 'password': ..., // لا ترسل كلمة المرور من هنا غالباً
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'type': _selectedType, // القيمة المختارة
        'status': _selectedStatus, // القيمة المختارة
        'email_verified': _emailVerified, // قيمة Checkbox
        // 'photo': ... // معالجة رفع ملف الصورة هنا
      };

      // TODO: معالجة رفع ملف الصورة إذا تم اختيار صورة جديدة (_pickedImage)
      // هذا يتطلب تعديل ApiService.updateUser ليقبل File أو MultipartFile
      // وإذا كان API يتطلب FormData أو MultipartRequest، ستحتاج لإعادة هيكلة طريقة إرسال الطلب في ApiService
      // For now, we will send user data without the photo file.

      try {
        await provider.updateUser(context, widget.user.userId!, userData); // استدعاء تابع التحديث

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المستخدم بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة تفاصيل المستخدم
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل التحديث: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية في الفورم (باستخدام مفتاح الفورم وتحكمات حقول النصوص)
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: ${e.toString()}')),
        );
      }
    }
  }

  // TODO: إضافة تابع لتغيير كلمة المرور (يفتح AlertDialog أو ينتقل لشاشة منفصلة)
  /*
  Future<void> _changePassword() async {
      // TODO: عرض AlertDialog لطلب كلمة المرور الجديدة وتأكيدها
      // TODO: استدعاء تابع في AdminUserProvider (أو AuthProvider) لتغيير كلمة المرور
      // هذا يتطلب تابعاً في ApiService مثل changeUserPassword(token, userId, oldPassword, newPassword, confirmNewPassword)
  }
  */


  @override
  void dispose() {
    // لا تنسى dispose لجميع حقول التحكم بالنصوص
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    // لا نحتاج dispose للـ dropdown/checkbox state أو لملف الصورة
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
              const Text('بيانات المستخدم الأساسية:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  // TODO: تحقق من عدم تكرار اسم المستخدم (باستثناء المستخدم الحالي) - يتم التحقق في Backend أيضاً
                  // هذا التحقق يمكن أن يتم في الواجهة أيضاً إذا أردت (بإرسال طلب API للتحقق)
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
                  // TODO: تحقق من تنسيق البريد الإلكتروني وعدم تكراره (باستثناء المستخدم الحالي) - يتم التحقق في Backend أيضاً
                  if (!value.contains('@')) {
                    return 'الرجاء إدخال بريد إلكتروني صالح';
                  }
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

              // حقل لتعديل email_verified (Checkbox/Switch)
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
              const Divider(height: 24),

              // TODO: إضافة خيار لتعديل كلمة المرور (ربما زر يفتح AlertDialog لطلب كلمة مرور جديدة وتأكيدها)
              ElevatedButton(
                onPressed: provider.isLoading ? null : () {
                  // TODO: تنفيذ منطق تغيير كلمة المرور
                  print('Change Password Tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('وظيفة تغيير كلمة المرور لم تنفذ.')),
                  );
                },
                child: const Text('تغيير كلمة المرور'),
              ),
              const SizedBox(height: 12.0),

              // TODO: إضافة خيار لرفع الصورة (Image Picker)
              const Text('صورة الملف الشخصي (اختياري):'),
              const SizedBox(height: 8.0),
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : () {
                  // TODO: تنفيذ منطق اختيار الصورة
                  print('Pick Image Tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('وظيفة اختيار الصورة لم تنفذ.')),
                  );
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('اختيار صورة من المعرض'),
              ),
              // TODO: عرض معاينة للصورة المختارة أو الصورة الحالية
               if (_pickedImage != null) Image.file(_pickedImage!, height: 100)
               else if (widget.user.photo != null) Image.network('...${widget.user.photo!}', height: 100),


              const Divider(height: 24),

              // TODO: إضافة خيارات لتعديل العلاقات (الملف الشخصي، المهارات، الشركة المرتبطة)
              // يمكن عرض أزرار للانتقال لشاشات تعديل العلاقات المنفصلة هنا
              if (widget.user.type == 'خريج' || widget.user.type == 'خبير استشاري') // فقط إذا كان نوع المستخدم يمتلك ملف شخصي ومهارات
                ElevatedButton(
                  onPressed: provider.isLoading ? null : () {
                    // TODO: الانتقال إلى شاشة تعديل الملف الشخصي
                    print('Edit Profile Tapped for related profile');
                    // تحتاج لتمرير بيانات الملف الشخصي (إذا لم تكن محملة بالفعل في كائن المستخدم)
                    // أو مجرد الانتقال لشاشة EditUserProfileScreen التي ستجلب بيانات الملف الشخصي للمستخدم الحالي (الأدمن)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة تعديل الملف الشخصي المرتبط لم تنفذ.')),
                    );
                  },
                  child: const Text('تعديل الملف الشخصي المرتبط'),
                ),
              const SizedBox(height: 12.0),
              if (widget.user.type == 'خريج' || widget.user.type == 'خبير استشاري') // فقط إذا كان نوع المستخدم يمتلك مهارات
                ElevatedButton(
                  onPressed: provider.isLoading ? null : () {
                    // TODO: الانتقال إلى شاشة تعديل المهارات
                    print('Edit Skills Tapped for related user');
                    // تحتاج لتمرير معرف المستخدم لـ EditUserSkillsScreen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة تعديل المهارات المرتبطة لم تنفذ.')),
                    );
                  },
                  child: const Text('تعديل المهارات المرتبطة'),
                ),
              const SizedBox(height: 12.0),
              if (widget.user.type == 'مدير شركة') // فقط إذا كان مدير شركة
                ElevatedButton(
                  onPressed: provider.isLoading ? null : () {
                    // TODO: الانتقال إلى شاشة تعديل الشركة المرتبطة
                    print('Edit Company Tapped for related manager');
                    // تحتاج لتمرير معرف الشركة المرتبطة
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة تعديل الشركة المرتبطة لم تنفذ.')),
                    );
                  },
                  child: const Text('تعديل الشركة المرتبطة'),
                ),
              // TODO: إضافة أزرار لإدارة فرص العمل/الدورات/المقالات التي أنشأها هذا المستخدم (خاصة إذا كان مدير/استشاري)
              // مشابه لما فعلناه في AdminCompanyDetailScreen لعرض وظائف ودورات الشركة


              const SizedBox(height: 24.0),
              // زر الحفظ (الإنشاء)
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveUser, // تعطيل الزر أثناء التحميل
                child: const Text('حفظ التعديلات'), // دائماً نص حفظ التعديلات
              ),
            ],
          ),
        ),
      ),
    );
  }
}