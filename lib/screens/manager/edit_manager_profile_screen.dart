// lib/screens/manager/edit_manager_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EditManagerProfileScreen extends StatefulWidget {
  final User user;
  const EditManagerProfileScreen({super.key, required this.user});

  @override
  State<EditManagerProfileScreen> createState() => _EditManagerProfileScreenState();
}

class _EditManagerProfileScreenState extends State<EditManagerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  // لتخزين الصورة الجديدة التي يتم اختيارها من الجهاز
  XFile? _imageFile;
  // لتتبع حالة تحميل النموذج
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  /// يختار صورة من معرض الصور.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // ضغط الصورة لتقليل حجمها
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      print("Failed to pick image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل اختيار الصورة'), backgroundColor: Colors.red),
      );
    }
  }

  /// يحدد الـ ImageProvider الصحيح لعرضه في CircleAvatar.
  ImageProvider? _getImageProvider() {
    // 1. إذا تم اختيار ملف جديد من الجهاز، استخدمه.
    if (_imageFile != null) {
      return FileImage(File(_imageFile!.path));
    }
    // 2. إذا لم يتم اختيار ملف جديد، تحقق مما إذا كان المستخدم لديه صورة مخزنة على الخادم.
    if (widget.user.photo != null && widget.user.photo!.isNotEmpty) {
      // !!! هام جدًا: استبدل هذا الرابط بعنوان URL الأساسي لموقعك !!!
      const String baseUrlForImages = 'https://powderblue-woodpecker-887296.hostingersite.com';
      return NetworkImage(baseUrlForImages + widget.user.photo!);
    }
    // 3. إذا لم يوجد أي مما سبق، أعد null (لن يتم عرض أي صورة).
    return null;
  }

  /// يرسل النموذج والبيانات المحدثة إلى الـ API.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // إذا كان النموذج غير صحيح، لا تكمل.
    }
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // بناء البيانات النصية التي سيتم إرسالها
    final Map<String, dynamic> profileData = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'phone': _phoneController.text,
    };

    // ملاحظة: تحديث الصورة يتطلب منطقًا خاصًا في ApiService و AuthProvider
    // لاستخدام multipart request. هذا الكود يفترض أن تحديث الصورة سيتم تنفيذه لاحقًا.
    // حاليًا، سيتم تحديث البيانات النصية فقط.
    // TODO: قم بتنفيذ تابع updateUserProfileWithPhoto في AuthProvider و ApiService.

    try {
      // استدعاء تابع التحديث من الـ provider
      await authProvider.updateUserProfile(profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح'), backgroundColor: Colors.green),
      );

      // العودة للشاشة السابقة بعد نجاح العملية
      if (mounted) {
        Navigator.pop(context);
      }
    } on ApiException catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: ${e.message}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        actions: [
          // إضافة زر حفظ في الـ AppBar
          if (!_isSubmitting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submitForm,
              tooltip: 'حفظ',
            )
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting, // تعطيل الواجهة أثناء التحميل
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // قسم تحديث الصورة
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    // استدعاء الدالة المساعدة لتحديد مصدر الصورة
                    backgroundImage: _getImageProvider(),
                    backgroundColor: Colors.grey.shade200,
                    // عرض أيقونة الكاميرا فقط إذا لم تكن هناك صورة لعرضها
                    child: _getImageProvider() == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('اضغط على الصورة لتغييرها'),
                const SizedBox(height: 24),

                // حقول النموذج
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الأول'),
                  validator: (value) => value!.isEmpty ? 'لا يمكن ترك هذا الحقل فارغاً' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الأخير'),
                  validator: (value) => value!.isEmpty ? 'لا يمكن ترك هذا الحقل فارغاً' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                // زر الحفظ الرئيسي
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ التغييرات'),
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}