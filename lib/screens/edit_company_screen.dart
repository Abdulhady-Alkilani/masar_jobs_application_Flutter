import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_company_provider.dart'; // لتنفيذ عملية التحديث
import '../models/company.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// قد تحتاج لاستيراد provider للمستخدمين (لأدمن) إذا كنت ستعرض قائمة للمدير، لكن في سياق مدير الشركة، هو يعدل شركته المرتبطة تلقائياً.


class EditCompanyScreen extends StatefulWidget {
  final Company company; // الشركة التي سيتم تعديلها (مطلوب دائماً لهذه الشاشة)

  const EditCompanyScreen({Key? key, required this.company}) : super(key: key);

  @override
  _EditCompanyScreenState createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  // حقول التحكم بالنصوص
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _detailedAddressController = TextEditingController();
  final TextEditingController _mediaController = TextEditingController(); // كمسار أو JSON
  final TextEditingController _webSiteController = TextEditingController();
  // حالة الشركة (Status) غالباً لا يعدلها المدير بنفسه، بل الأدمن. لذا لن نضع حقلها هنا.


  @override
  void initState() {
    super.initState();
    // تعبئة الحقول بالبيانات الحالية للشركة الممررة
    _nameController.text = widget.company.name ?? '';
    _emailController.text = widget.company.email ?? '';
    _phoneController.text = widget.company.phone ?? '';
    _descriptionController.text = widget.company.description ?? '';
    _countryController.text = widget.company.country ?? '';
    _cityController.text = widget.company.city ?? '';
    _detailedAddressController.text = widget.company.detailedAddress ?? '';
    _mediaController.text = widget.company.media ?? '';
    _webSiteController.text = widget.company.webSite ?? '';

    // TODO: إذا كنت ستسمح باختيار/تعديل الوسائط (Media) بشكل تفاعلي، استخدم حزمة اختيار ملفات
  }

  // تابع لحفظ التعديلات
  Future<void> _saveCompany() async {
    // إغلاق لوحة المفاتيح
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<ManagedCompanyProvider>(context, listen: false);

      // بيانات الشركة المراد إرسالها (Manager لا يرسل UserID، ولا Status)
      final companyData = {
        'Name': _nameController.text,
        'Email': _emailController.text.isEmpty ? null : _emailController.text,
        'Phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'Description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'Country': _countryController.text.isEmpty ? null : _countryController.text,
        'City': _cityController.text.isEmpty ? null : _cityController.text,
        'Detailed Address': _detailedAddressController.text.isEmpty ? null : _detailedAddressController.text,
        'Media': _mediaController.text.isEmpty ? null : _mediaController.text, // أو معالجة رفع ملف
        'Web site': _webSiteController.text.isEmpty ? null : _webSiteController.text, // تأكد من اسم الحقل
        // 'status': _selectedStatus, // المدير لا يعدل الحالة
        // 'UserID': ..., // المدير لا يرسل UserID، backend يضعه تلقائياً
      };

      try {
        // عملية تعديل (دائماً في هذه الشاشة)
        // ManagedCompanyProvider.updateManagedCompany لا يتطلب Company ID في الاستدعاء،
        // لأنه يقوم بتحديث الشركة المرتبطة بالمدير المصادق عليه تلقائياً.
        await provider.updateManagedCompany(context, companyData); // <--- استدعاء تابع التحديث


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الشركة بنجاح.')),
        );
        // بعد النجاح، العودة إلى شاشة شركة المدير
        Navigator.pop(context);

      } on ApiException catch (e) {
        String errorMessage = 'فشل التحديث: ${e.message}';
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
          SnackBar(content: Text('فشل التحديث: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _detailedAddressController.dispose();
    _mediaController.dispose();
    _webSiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة التحميل من ManagedCompanyProvider عند الحفظ
    final provider = Provider.of<ManagedCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الشركة'), // دائماً شاشة تعديل
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
              // حقول بيانات الشركة
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
                // validator: (value) { ... }, // تحقق من تنسيق البريد
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
              // حالة الشركة (Status) لا يتم تعديلها من هنا بواسطة المدير

              const SizedBox(height: 24),
              // زر الحفظ
              ElevatedButton(
                onPressed: provider.isLoading ? null : _saveCompany, // تعطيل الزر أثناء التحميل
                child: const Text('حفظ التعديلات'), // دائماً نص حفظ التعديلات
              ),
            ],
          ),
        ),
      ),
    );
  }
}