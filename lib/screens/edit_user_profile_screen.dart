import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // لتحديث الملف الشخصي
import '../models/user.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
import '../models/profile.dart'; // تأكد من المسار

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({Key? key}) : super(key: key);

  @override
  _EditUserProfileScreenState createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص لبيانات المستخدم الأساسية التي يمكن تعديلها
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  // حقول التحكم بالنصوص لبيانات الملف الشخصي
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();
  final TextEditingController _personalDescriptionController = TextEditingController();
  final TextEditingController _technicalDescriptionController = TextEditingController();
  final TextEditingController _gitHyperLinkController = TextEditingController();


  @override
  void initState() {
    super.initState();
    // تعبئة الحقول بالبيانات الحالية للمستخدم والملف الشخصي
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneController.text = user.phone ?? '';
      if (user.profile != null) {
        _universityController.text = user.profile!.university ?? '';
        _gpaController.text = user.profile!.gpa ?? '';
        _personalDescriptionController.text = user.profile!.personalDescription ?? '';
        _technicalDescriptionController.text = user.profile!.technicalDescription ?? '';
        _gitHyperLinkController.text = user.profile!.gitHyperLink ?? '';
      }
    }
  }


  // تابع لحفظ التعديلات
  Future<void> _saveProfile() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final User? currentUser = authProvider.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: بيانات المستخدم غير متوفرة.')),
        );
        return;
      }

      // بيانات الملف الشخصي المراد إرسالها للتحديث
      final Map<String, dynamic> profileData = { // <--- تأكد من نوع الخريطة
        // بيانات المستخدم الأساسية التي تسمح الـ API بتعديلها عبر مسار /profile
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,

        // بيانات الملف الشخصي
        'University': _universityController.text.isEmpty ? null : _universityController.text,
        'GPA': _gpaController.text.isEmpty ? null : _gpaController.text,
        'Personal Description': _personalDescriptionController.text.isEmpty ? null : _personalDescriptionController.text,
        'Technical Description': _technicalDescriptionController.text.isEmpty ? null : _technicalDescriptionController.text,
        'Git Hyper Link': _gitHyperLinkController.text.isEmpty ? null : _gitHyperLinkController.text,
        // TODO: إضافة قيمة حقل الصورة إذا تم تنفيذه
      };

      try {
        // استدعاء تابع التحديث في AuthProvider بتمرير بارامتر البيانات فقط
        await authProvider.updateUserProfile(profileData); // <--- التصحيح هنا

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة الملف الشخصي
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل التحديث: ${e.message}';
        if (e.errors != null) {
          // يمكنك معالجة أخطاء التحقق هنا بشكل أفضل وعرضها للمستخدم
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
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
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _gpaController.dispose();
    _personalDescriptionController.dispose();
    _technicalDescriptionController.dispose();
    _gitHyperLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من AuthProvider عند الحفظ
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
      ),
      body: authProvider.isLoading // إذا كان Provider يحمل بيانات (عند الحفظ)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
              const Divider(height: 24),

              const Text('بيانات الملف الشخصي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'الجامعة'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gpaController,
                decoration: const InputDecoration(labelText: 'المعدل التراكمي'),
                keyboardType: TextInputType.numberWithOptions(decimal: true), // للسماح بالأرقام العشرية
                // validator: (value) { ... }, // يمكن إضافة تحقق لرقمي
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personalDescriptionController,
                decoration: const InputDecoration(labelText: 'نبذة شخصية'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _technicalDescriptionController,
                decoration: const InputDecoration(labelText: 'نبذة اختصاصية'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gitHyperLinkController,
                decoration: const InputDecoration(labelText: 'رابط GitHub'),
                keyboardType: TextInputType.url,
                // validator: (value) { ... }, // تحقق من تنسيق URL
              ),
              // TODO: إضافة حقل لتعديل الصورة (إذا كان API يسمح بذلك عبر هذا المسار)
              // TODO: إضافة خيار لتغيير كلمة المرور (زر يفتح AlertDialog أو شاشة منفصلة)

              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _saveProfile, // تعطيل الزر أثناء التحميل
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}