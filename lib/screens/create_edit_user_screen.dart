import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../providers/auth_provider.dart'; // للحصول على المستخدم الحالي (الأدمن)
import '../models/user.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException


class CreateEditUserScreen extends StatefulWidget {
  final User? user; // إذا كان null، فهي شاشة إضافة مستخدم جديد. إذا كان موجوداً، فهي شاشة تعديل هذا المستخدم.

  const CreateEditUserScreen({Key? key, this.user}) : super(key: key);

  @override
  _CreateEditUserScreenState createState() => _CreateEditUserScreenState();
}

class _CreateEditUserScreenState extends State<CreateEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  final TextEditingController _userIdController = TextEditingController(); // للأدمن فقط: لتعيين/عرض معرف المستخدم
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // لكلمة المرور الجديدة عند الإنشاء أو التعديل
  final TextEditingController _passwordConfirmationController = TextEditingController(); // لتأكيد كلمة المرور عند الإنشاء
  final TextEditingController _phoneController = TextEditingController();
  // حقول Dropdown
  String? _selectedType; // نوع المستخدم
  String? _selectedStatus; // حالة المستخدم

  // TODO: قائمة أنواع المستخدمين (يجب أن تتطابق مع enum في Backend)
  final List<String> _userTypes = ['خريج', 'خبير استشاري', 'مدير شركة', 'Admin'];
  // TODO: قائمة حالات المستخدمين (يجب أن تتطابق مع enum في Backend)
  final List<String> _userStatuses = ['مفعل', 'معلق', 'محذوف'];


  bool get isEditing => widget.user != null; // للتحقق بسهولة إذا كانت شاشة تعديل

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقول بالبيانات الحالية للمستخدم
    if (isEditing) {
      _userIdController.text = widget.user!.userId?.toString() ?? ''; // عرض UserID (للقراءة فقط غالباً في التعديل)
      _firstNameController.text = widget.user!.firstName ?? '';
      _lastNameController.text = widget.user!.lastName ?? '';
      _usernameController.text = widget.user!.username ?? '';
      _emailController.text = widget.user!.email ?? '';
      _phoneController.text = widget.user!.phone ?? '';
      _selectedType = widget.user!.type; // تعيين القيمة الافتراضية لنوع الحساب
      _selectedStatus = widget.user!.status; // تعيين القيمة الافتراضية لحالة الحساب
      // لا نملأ حقول كلمة المرور هنا لأسباب أمنية، يتم إدخال كلمة مرور جديدة فقط إذا أراد الأدمن تغييرها.
    } else {
      // في حالة الإضافة، تعيين قيم افتراضية إذا لزم الأمر
      // يمكن تعيين نوع المستخدم وحالته الافتراضية عند الإنشاء
      _selectedType = _userTypes.isNotEmpty ? _userTypes.first : null;
      _selectedStatus = _userStatuses.isNotEmpty ? _userStatuses.first : null;
    }

    // TODO: إذا كانت هناك بيانات أخرى قابلة للتعديل (مثل الصورة email_verified) أضف حقولها هنا.
  }

  // تابع لحفظ (إنشاء أو تعديل) المستخدم
  Future<void> _saveUser() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminUserProvider>(context, listen: false);

      // بيانات المستخدم المراد إرسالها
      final userData = {
        // UserID مطلوب فقط عند الإنشاء بواسطة الأدمن، ولا يتم إرساله في Body عند التعديل (هو جزء من URL)
        if (!isEditing) 'UserID': int.tryParse(_userIdController.text), // مطلوب عند الإنشاء فقط للأدمن
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'type': _selectedType, // القيمة المختارة
        'status': _selectedStatus, // القيمة المختارة
        // TODO: إضافة قيمة حقل الصورة email_verified هنا
        // 'email_verified': true/false
        // 'photo': _photoController.text.isEmpty ? null : _photoController.text,

        // كلمة المرور يتم تضمينها فقط إذا تم إدخالها (في التعديل هي اختيارية، في الإنشاء هي مطلوبة و validation يتكفل بذلك)
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
        // لا ترسل password_confirmation إلى API، هي فقط للتحقق في الواجهة
      };

      try {
        if (isEditing) {
          // عملية تعديل
          if (widget.user!.userId == null) {
            throw Exception('معرف المستخدم غير متوفر للتعديل.');
          }
          await provider.updateUser(context, widget.user!.userId!, userData); // استدعاء تابع التحديث

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المستخدم بنجاح.')),
          );

        } else {
          // عملية إنشاء
          // تأكد أن UserID تم إدخاله عند الإنشاء
          if (userData['UserID'] == null) { // هذا التحقق مطلوب بناءً على Validation في الحقل
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الرجاء إدخال معرف المستخدم.')),
            );
            return;
          }
          // في الإنشاء، كلمة المرور مطلوبة و Validation يتكفل بذلك
          await provider.createUser(context, userData); // استدعاء تابع الإنشاء

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المستخدم بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى الشاشة السابقة (قائمة المستخدمين)
        // في حالة التعديل من شاشة التفاصيل، العودة ستكون لشاشة التفاصيل
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.message}';
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
          SnackBar(content: Text('فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.toString()}')),
        );
      }
    }
  }


  @override
  void dispose() {
    // لا تنسى dispose لجميع حقول التحكم بالنصوص
    _userIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _phoneController.dispose();
    // لا نحتاج dispose للـ dropdown controllers
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من AdminUserProvider عند الحفظ
    final provider = Provider.of<AdminUserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم جديد'),
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
              // حقل User ID (للقراءة فقط عند التعديل، وللإدخال عند الإنشاء)
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'معرف المستخدم (UserID)'),
                keyboardType: TextInputType.number,
                readOnly: isEditing, // جعل الحقل للقراءة فقط عند التعديل
                validator: (value) {
                  // مطلوب عند الإنشاء
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'الرجاء إدخال معرف المستخدم';
                  }
                  // تحقق من أنه رقم إذا تم إدخاله
                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح لمعرف المستخدم';
                  }
                  // TODO: يمكن إضافة تحقق هنا للتأكد من عدم تكرار UserID عند الإنشاء (يتم التحقق في Backend أيضاً)
                  return null;
                },
              ),
              const SizedBox(height: 12),

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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المستخدم';
                  }
                  // TODO: تحقق من عدم تكرار اسم المستخدم (باستثناء المستخدم الحالي في حالة التعديل)
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال البريد الإلكتروني';
                  }
                  // TODO: تحقق من تنسيق البريد الإلكتروني وعدم تكراره (باستثناء المستخدم الحالي في حالة التعديل)
                  if (!value.contains('@')) {
                    return 'الرجاء إدخال بريد إلكتروني صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                // لا حاجة لـ validator إذا كان اختياري، أو تحقق من التنسيق إذا أدخل شيء
              ),
              const SizedBox(height: 12),

              // حقول كلمة المرور (مطلوبة عند الإنشاء، اختيارية عند التعديل)
              if (!isEditing) ...[ // عرض الحقول فقط عند الإنشاء
                const Text('كلمة المرور (مطلوبة عند الإنشاء):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // مطلوبة عند الإنشاء
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    // TODO: يمكنك إضافة متطلبات تعقيد لكلمة المرور هنا
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordConfirmationController,
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // مطلوبة عند الإنشاء
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ] else ...[ // عند التعديل، عرض خيار لتغيير كلمة المرور
                // TODO: يمكن إضافة زر يفتح AlertDialog لتغيير كلمة المرور عند التعديل
                // أو ببساطة إضافة حقلين لكلمة المرور الجديدة وتأكيدها هنا إذا تم إدخالهما يتم إرسالهما
                // لنضيف حقلين اختياريين لتغيير كلمة المرور هنا
                const Text('تغيير كلمة المرور (اختياري عند التعديل):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _passwordController, // إعادة استخدام Controller لكلمة المرور الجديدة
                  decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                  obscureText: true,
                  validator: (value) {
                    // لا يوجد validator هنا إذا كان اختيارياً، يتم التحقق في Backend
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordConfirmationController, // إعادة استخدام Controller للتأكيد
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة'),
                  obscureText: true,
                  validator: (value) {
                    // إذا تم إدخال كلمة مرور جديدة، يجب تأكيدها
                    if (_passwordController.text.isNotEmpty && (value == null || value.isEmpty)) {
                      return 'الرجاء تأكيد كلمة المرور الجديدة';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور الجديدة غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],


              // حقول Dropdown للنوع والحالة
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'نوع الحساب'),
                value: _selectedType, // استخدام القيمة مباشرة
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
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار نوع الحساب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'حالة الحساب'),
                value: _selectedStatus, // استخدام القيمة مباشرة
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
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار حالة الحساب';
                  }
                  return null;
                },
              ),
              // TODO: إضافة حقل لتعديل email_verified (Checkbox/Switch)
              // TODO: إضافة خيار لتعديل الصورة (Image Picker)
              // TODO: إضافة خيارات لتعديل العلاقات (الملف الشخصي، المهارات، الشركة المرتبطة) - هذه قد تكون في شاشات منفصلة يربط إليها الأدمن من شاشة التفاصيل


              const SizedBox(height: 24.0),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveUser, // تعطيل الزر أثناء التحميل
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء المستخدم'), // نص الزر يتغير بناءً على وضع الشاشة
              ),
            ],
          ),
        ),
      ),
    );
  }
}