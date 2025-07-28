// lib/screens/manager/edit_company_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/managed_company_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/rive_loading_indicator.dart';

class EditCompanyScreen extends StatefulWidget {
  const EditCompanyScreen({super.key});
  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  // لا نحتاج لـ form key لأننا لا نقوم بالتحقق من الصحة هنا
  late Map<String, dynamic> _companyData;

  @override
  void initState() {
    super.initState();
    final company = Provider.of<ManagedCompanyProvider>(context, listen: false).company;
    _companyData = {
      'Name': company?.name ?? '',
      'Email': company?.email ?? '',
      'Phone': company?.phone ?? '',
      'Description': company?.description ?? '',
      'Country': company?.country ?? '',
      'City': company?.city ?? '',
      'Detailed Address': company?.detailedAddress ?? '',
      'Web site': company?.webSite ?? '',
    };
  }

  // دالة لفتح حوار التعديل
  Future<void> _showEditDialog(String fieldKey, String title, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) async {
    final controller = TextEditingController(text: _companyData[fieldKey]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $title'),
        content: TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _companyData[fieldKey] = result;
      });
    }
  }

  Future<void> _saveCompany() async {
    final provider = Provider.of<ManagedCompanyProvider>(context, listen: false);
    try {
      await provider.updateManagedCompany(context, _companyData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الشركة'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحديث: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagedCompanyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل بيانات الشركة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveCompany,
        label: const Text('حفظ التغييرات'),
        icon: provider.isLoading ? const RiveLoadingIndicator(size: 24) : const Icon(Icons.save_alt_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoCard(
            icon: Icons.business_outlined,
            title: 'اسم الشركة',
            value: _companyData['Name'],
            placeholder: 'اسم شركتك الرسمي',
            onTap: () => _showEditDialog('Name', 'اسم الشركة'),
          ),
          _buildInfoCard(
            icon: Icons.description_outlined,
            title: 'وصف الشركة',
            value: _companyData['Description'],
            placeholder: 'نبذة تعريفية عن نشاط الشركة',
            onTap: () => _showEditDialog('Description', 'وصف الشركة', maxLines: 5),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          _buildInfoCard(
            icon: Icons.email_outlined,
            title: 'البريد الإلكتروني للشركة',
            value: _companyData['Email'],
            placeholder: 'بريد التواصل الرسمي',
            onTap: () => _showEditDialog('Email', 'البريد الإلكتروني', keyboardType: TextInputType.emailAddress),
          ),
          _buildInfoCard(
            icon: Icons.phone_outlined,
            title: 'هاتف الشركة',
            value: _companyData['Phone'],
            placeholder: 'رقم الهاتف للتواصل',
            onTap: () => _showEditDialog('Phone', 'هاتف الشركة', keyboardType: TextInputType.phone),
          ),
          _buildInfoCard(
            icon: Icons.public_outlined,
            title: 'الموقع الإلكتروني',
            value: _companyData['Web site'],
            placeholder: 'مثال: https://company.com',
            onTap: () => _showEditDialog('Web site', 'الموقع الإلكتروني', keyboardType: TextInputType.url),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          _buildInfoCard(
            icon: Icons.location_city_outlined,
            title: 'المدينة والدولة',
            value: '${_companyData['City']}, ${_companyData['Country']}',
            placeholder: 'مثال: الرياض، المملكة العربية السعودية',
            onTap: () async {
              await _showEditDialog('Country', 'الدولة');
              await _showEditDialog('City', 'المدينة');
            },
          ),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            title: 'العنوان التفصيلي',
            value: _companyData['Detailed Address'],
            placeholder: 'اسم الشارع، رقم المبنى...',
            onTap: () => _showEditDialog('Detailed Address', 'العنوان التفصيلي', maxLines: 2),
          ),
        ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required String placeholder, required VoidCallback onTap}) {
    final bool hasValue = value.isNotEmpty && !value.startsWith(', ');
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          hasValue ? value : placeholder,
          style: TextStyle(color: hasValue ? Colors.black87 : Colors.grey.shade600, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
      ),
    );
  }
}