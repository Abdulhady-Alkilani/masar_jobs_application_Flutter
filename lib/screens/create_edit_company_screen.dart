import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_company_provider.dart'; // لتنفيذ عمليات الإنشاء/التحديث
import '../models/company.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// import '../models/api_exception.dart'; // تأكد من استيراد ApiException بشكل صحيح
// قد تحتاج لاستيراد provider للمستخدمين لاختيار المدير (UserID)


class CreateEditCompanyScreen extends StatefulWidget {
  final Company? company; // إذا كان null، فهي شاشة إضافة. إذا كان موجوداً، فهي شاشة تعديل.

  const CreateEditCompanyScreen({Key? key, this.company}) : super(key: key);

  @override
  _CreateEditCompanyScreenState createState() => _CreateEditCompanyScreenState();
}

class _CreateEditCompanyScreenState extends State<CreateEditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController(); // لتعيين المدير (لـ Admin)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _detailedAddressController = TextEditingController();
  final TextEditingController _mediaController = TextEditingController(); // كمسار أو JSON
  final TextEditingController _webSiteController = TextEditingController();
  String? _selectedStatus; // للتحكم في حالة الشركة (Dropdown)


  // TODO: قائمة حالات الشركة المتاحة (يجب أن تأتي من Backend أو ثابت هنا)
  final List<String> _availableStatuses = ['pending', 'approved', 'rejected'];


  bool get isEditing => widget.company != null; // للتحقق بسهولة إذا كانت شاشة تعديل

  @override
  void initState() {
    super.initState();
    // إذا كانت شاشة تعديل، قم بتعبئة الحقول بالبيانات الحالية للشركة
    if (isEditing) {
      _userIdController.text = widget.company!.userId?.toString() ?? '';
      _nameController.text = widget.company!.name ?? '';
      _emailController.text = widget.company!.email ?? '';
      _phoneController.text = widget.company!.phone ?? '';
      _descriptionController.text = widget.company!.description ?? '';
      _countryController.text = widget.company!.country ?? '';
      _cityController.text = widget.company!.city ?? '';
      _detailedAddressController.text = widget.company!.detailedAddress ?? '';
      _mediaController.text = widget.company!.media ?? '';
      _webSiteController.text = widget.company!.webSite ?? '';
      _selectedStatus = widget.company!.status; // تعيين القيمة الافتراضية للقائمة المنسدلة
    } else {
      // في حالة الإضافة، تعيين حالة افتراضية (مثلاً 'pending' إذا كان الأدمن لا يوافق مباشرة، أو 'approved')
      _selectedStatus = 'pending'; // مثال
    }

    // TODO: إذا كنت ستسمح باختيار المدير (UserID) من قائمة، قم بجلب قائمة المستخدمين
  }

  // تابع لحفظ (إنشاء أو تعديل) الشركة
  Future<void> _saveCompany() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<AdminCompanyProvider>(context, listen: false);

      final companyData = {
        // UserID مطلوب عند إنشاء شركة بواسطة الأدمن، واختياري عند تعديلها
        if (_userIdController.text.isNotEmpty) 'UserID': int.tryParse(_userIdController.text), // تحويل النص إلى عدد صحيح
        'Name': _nameController.text,
        'Email': _emailController.text.isEmpty ? null : _emailController.text,
        'Phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'Description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'Country': _countryController.text.isEmpty ? null : _countryController.text,
        'City': _cityController.text.isEmpty ? null : _cityController.text,
        'Detailed Address': _detailedAddressController.text.isEmpty ? null : _detailedAddressController.text,
        'Media': _mediaController.text.isEmpty ? null : _mediaController.text, // أو معالجة رفع ملف
        'Web site': _webSiteController.text.isEmpty ? null : _webSiteController.text, // تأكد من اسم الحقل
        'status': _selectedStatus, // القيمة المختارة من Dropdown
      };

      try {
        if (isEditing) {
          // عملية تعديل
          if (widget.company!.companyId == null) {
            throw Exception('معرف الشركة غير متوفر للتعديل.');
          }
          await provider.updateCompany(context, widget.company!.companyId!, companyData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الشركة بنجاح.')),
          );
        } else {
          // عملية إنشاء
          // تأكد أن UserID تم إدخاله عند الإنشاء
          if (companyData['UserID'] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الرجاء إدخال معرف المدير عند إضافة شركة جديدة.')),
            );
            return;
          }
          await provider.createCompany(context, companyData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الشركة بنجاح.')),
          );
        }
        // بعد النجاح، العودة إلى الشاشة السابقة
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل ${isEditing ? 'التحديث' : 'الإنشاء'}: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
          // TODO: يمكن معالجة أخطاء التحقق وعرضها بجانب الحقول المعنية
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
    _userIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _detailedAddressController.dispose();
    _mediaController.dispose();
    _webSiteController.dispose();
    // لا نحتاج dispose للـ dropdown controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من AdminCompanyProvider عند الحفظ
    final provider = Provider.of<AdminCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل شركة' : 'إضافة شركة جديدة'),
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
              // حقل User ID للمدير (خاص بالأدمن فقط)
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'معرف المدير (UserID)'),
                keyboardType: TextInputType.number,
                enabled: !isEditing, // لا يمكن تغيير المدير بعد الإنشاء (افتراضاً)
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    // مطلوب عند الإنشاء
                    return 'الرجاء إدخال معرف المدير';
                  }
                  if (int.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح لمعرف المدير';
                  }
                  // TODO: تحقق من وجود UserID وكونه لمدير شركة (اختياري في الواجهة، يتم التحقق في Backend)
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // حقول بيانات الشركة الأخرى
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الشركة'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الشركة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                // validator: (value) { ... }, // تحقق من تنسيق البريد وعدم تكراره
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف عن الشركة'),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'الدولة'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'المدينة'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailedAddressController,
                decoration: const InputDecoration(labelText: 'العنوان المفصل'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mediaController,
                decoration: const InputDecoration(labelText: 'وسائط (مسارات صور/فيديو)'),
                // يمكن أن يكون هذا حقل اختيار ملفات بدلاً من نص
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _webSiteController,
                decoration: const InputDecoration(labelText: 'رابط الموقع الإلكتروني'),
                keyboardType: TextInputType.url,
                // validator: (value) { ... }, // تحقق من تنسيق URL
              ),
              const SizedBox(height: 12),
              // قائمة منسدلة لحالة الشركة
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'الحالة'),
                value: _selectedStatus, // استخدام القيمة مباشرة
                items: _availableStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _selectedStatus = newValue; // تحديث القيمة
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار الحالة';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveCompany, // تعطيل الزر أثناء التحميل
                child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء الشركة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}