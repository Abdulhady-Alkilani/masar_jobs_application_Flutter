import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/public_company_provider.dart'; // نستخدم نفس Provider العام لجلب التفاصيل
import '../models/company.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// قد تحتاج لاستيراد حزم لفتح الروابط (url_launcher) أو عرض الصور


class CompanyDetailScreen extends StatefulWidget {
  final int companyId; // معرف الشركة الذي سنعرض تفاصيلها

  const CompanyDetailScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  _CompanyDetailScreenState createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  Company? _company; // لتخزين بيانات الشركة الفردية
  String? _companyError; // لتخزين خطأ جلب الشركة
  bool _isLoading = false; // حالة تحميل خاصة بهذه الشاشة

  @override
  void initState() {
    super.initState();
    _fetchCompany(); // جلب تفاصيل الشركة عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل الشركة المحددة
  Future<void> _fetchCompany() async {
    setState(() { _isLoading = true; _companyError = null; });
    // نستخدم تابع fetchCompany من PublicCompanyProvider لأنه يجلب شركة واحدة بمعرفها
    final companyProvider = Provider.of<PublicCompanyProvider>(context, listen: false);

    try {
      final fetchedCompany = await companyProvider.fetchCompany(widget.companyId);
      setState(() {
        _company = fetchedCompany;
        _companyError = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _company = null;
        _companyError = e.message;
      });
    } catch (e) {
      setState(() {
        _company = null;
        _companyError = 'فشل جلب تفاصيل الشركة: ${e.toString()}';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // TODO: تابع لفتح رابط الموقع الإلكتروني (يتطلب url_launcher)
  /*
   Future<void> _launchUrl(String urlString) async {
     final Uri url = Uri.parse(urlString);
     if (!await launchUrl(url)) {
       throw Exception('Could not launch $url');
     }
   }
   */


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا لأننا نستخدم حالة تحميل خاصة بالشاشة (_isLoading)
    //final companyProvider = Provider.of<PublicCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_company?.name ?? 'تفاصيل الشركة'),
      ),
      body: _isLoading // حالة التحميل الخاصة بالشاشة
          ? const Center(child: CircularProgressIndicator())
          : _companyError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: ${_companyError!}'))
          : _company == null // بيانات غير موجودة بعد التحميل
          ? const Center(child: Text('الشركة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الشركة
            Text(
              _company!.name ?? 'بدون اسم',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_company!.status != null)
              Text(
                  'الحالة: ${_company!.status!}',
                  style: TextStyle(fontSize: 16, color: _company!.status == 'approved' ? Colors.green : Colors.orange)
              ),
            const SizedBox(height: 8),
            if (_company!.description != null) ...[
              const Text('عن الشركة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_company!.description!),
              const SizedBox(height: 16),
            ],
            if (_company!.email != null) Text('البريد الإلكتروني: ${_company!.email!}'),
            if (_company!.phone != null) Text('رقم الهاتف: ${_company!.phone!}'),
            if (_company!.country != null) Text('الدولة: ${_company!.country!}'),
            if (_company!.city != null) Text('المدينة: ${_company!.city!}'),
            if (_company!.detailedAddress != null) Text('العنوان المفصل: ${_company!.detailedAddress!}'),
            if (_company!.webSite != null) ...[
              const Text('الموقع الإلكتروني:', style: TextStyle(fontWeight: FontWeight.bold)),
              // يمكن إضافة زر لفتح الرابط
              InkWell(
                onTap: () {
                  // TODO: استدعاء تابع _launchUrl هنا
                  print('Website tapped: ${_company!.webSite!}');
                  // _launchUrl(_company!.webSite!);
                },
                child: Text(
                  _company!.webSite!,
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
            // TODO: عرض روابط الوسائط (Media) إذا كانت موجودة وتنسيقها (قد تكون JSON string تحتاج لفك ترميز)

            const Divider(height: 24),

            // TODO: يمكن عرض قائمة بفرص العمل التابعة لهذه الشركة هنا (إذا كان API يوفر مساراً لذلك)
            // مثلاً: GET /api/v1/companies/{company_id}/jobs
            const Text('فرص العمل من هذه الشركة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('غير متاح حالياً.', style: TextStyle(fontStyle: FontStyle.italic)), // Placeholder

            // TODO: يمكن عرض قائمة بالدورات التابعة لهذه الشركة هنا (إذا كان API يوفر مساراً لذلك)
            const SizedBox(height: 16),
            const Text('الدورات التدريبية من هذه الشركة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('غير متاح حالياً.', style: TextStyle(fontStyle: FontStyle.italic)), // Placeholder

          ],
        ),
      ),
    );
  }
}