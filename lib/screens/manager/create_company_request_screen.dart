// lib/screens/manager/create_company_request_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/managed_company_provider.dart';
import '../../services/api_service.dart';

class CreateCompanyRequestScreen extends StatefulWidget {
  const CreateCompanyRequestScreen({super.key});

  @override
  State<CreateCompanyRequestScreen> createState() => _CreateCompanyRequestScreenState();
}

class _CreateCompanyRequestScreenState extends State<CreateCompanyRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  //  ----->>> هنا تم التصحيح <<<-----
  // تم تغيير النوع إلى Map<String, dynamic> ليقبل أنواعًا مختلفة وقيم null
  final Map<String, dynamic> _companyData = {
    'Name': '',
    'Email': '',
    'Phone': '',
    'Description': '',
    'Country': '',
    'City': '',
    'Detailed Address': '',
    'Web site': '',
  };

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<ManagedCompanyProvider>(context, listen: false);

      try {
        await provider.createManagedCompany(context, _companyData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلبك بنجاح وسيتم مراجعته.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الطلب: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب إنشاء ملف شركة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'اسم الشركة'),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                onSaved: (v) => _companyData['Name'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني للشركة'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                onSaved: (v) => _companyData['Email'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'هاتف الشركة'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _companyData['Phone'] = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'وصف قصير عن الشركة'),
                maxLines: 4,
                //  ----->>> السطر الذي كان به الخطأ يعمل الآن بشكل صحيح <<<-----
                onSaved: (v) => _companyData['Description'] = v,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('إرسال الطلب'),
              )
            ],
          ),
        ),
      ),
    );
  }
}