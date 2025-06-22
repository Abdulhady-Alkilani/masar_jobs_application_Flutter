// lib/screens/manager/edit_company_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/managed_company_provider.dart';
import '../../models/company.dart';
import '../../services/api_service.dart';

class EditCompanyScreen extends StatefulWidget {
  final Company company;

  const EditCompanyScreen({super.key, required this.company});

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _companyData;

  // Controllers to manage form fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();

    // Initialize the form data from the passed company object
    _companyData = widget.company.toJson();

    // Initialize text controllers
    _nameController = TextEditingController(text: _companyData['Name']);
    _emailController = TextEditingController(text: _companyData['Email']);
    _phoneController = TextEditingController(text: _companyData['Phone']);
    _descriptionController = TextEditingController(text: _companyData['Description']);
    _countryController = TextEditingController(text: _companyData['Country']);
    _cityController = TextEditingController(text: _companyData['City']);
    _addressController = TextEditingController(text: _companyData['Detailed Address']);
    _websiteController = TextEditingController(text: _companyData['Web site']);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<ManagedCompanyProvider>(context, listen: false);

      try {
        await provider.updateManagedCompany(context, _companyData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات الشركة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the previous screen on success
        Navigator.pop(context);
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحديث: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to free up resources
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider to show a loading indicator during the API call
    final provider = Provider.of<ManagedCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل بيانات الشركة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo/Image Section
              // TODO: Add image picker logic here if you want to allow logo updates
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.business, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              _buildTextFormField(
                controller: _nameController,
                label: 'اسم الشركة',
                onSaved: (value) => _companyData['Name'] = value,
              ),
              _buildTextFormField(
                controller: _emailController,
                label: 'البريد الإلكتروني للشركة',
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => _companyData['Email'] = value,
              ),
              _buildTextFormField(
                controller: _phoneController,
                label: 'رقم هاتف الشركة',
                keyboardType: TextInputType.phone,
                onSaved: (value) => _companyData['Phone'] = value,
              ),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'وصف الشركة',
                maxLines: 4,
                onSaved: (value) => _companyData['Description'] = value,
              ),
              _buildTextFormField(
                controller: _countryController,
                label: 'الدولة',
                onSaved: (value) => _companyData['Country'] = value,
              ),
              _buildTextFormField(
                controller: _cityController,
                label: 'المدينة',
                onSaved: (value) => _companyData['City'] = value,
              ),
              _buildTextFormField(
                controller: _addressController,
                label: 'العنوان التفصيلي',
                onSaved: (value) => _companyData['Detailed Address'] = value,
              ),
              _buildTextFormField(
                controller: _websiteController,
                label: 'الموقع الإلكتروني',
                keyboardType: TextInputType.url,
                onSaved: (value) => _companyData['Web site'] = value,
              ),

              const SizedBox(height: 32),

              // Submit Button
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitForm,
                child: const Text('حفظ التعديلات'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to reduce repetitive code for TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Function(String?) onSaved,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }
}