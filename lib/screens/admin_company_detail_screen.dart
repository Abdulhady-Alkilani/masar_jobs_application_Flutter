import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_company_provider.dart'; // لجلب وتحديث وحذف
import '../models/company.dart'; // تأكد من المسار
import '../models/user.dart'; // تأكد من المسار (لبيانات المدير)
import '../services/api_service.dart'; // لاستخدام ApiException
// استيراد شاشة التعديل
import 'create_edit_company_screen.dart'; // <--- تأكد من المسار
// قد تحتاج لاستيراد شاشات إدارة موارد الشركة لهذا المدير (وظائف، دورات)

class AdminCompanyDetailScreen extends StatefulWidget {
  final int companyId; // معرف الشركة

  const AdminCompanyDetailScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  _AdminCompanyDetailScreenState createState() => _AdminCompanyDetailScreenState();
}

class _AdminCompanyDetailScreenState extends State<AdminCompanyDetailScreen> {
  Company? _company;
  String? _companyError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCompany(); // جلب تفاصيل الشركة عند التهيئة
  }

  // تابع لجلب تفاصيل الشركة
  Future<void> _fetchCompany() async {
    setState(() { _isLoading = true; _companyError = null; });
    final adminCompanyProvider = Provider.of<AdminCompanyProvider>(context, listen: false);

    try {
      // TODO: إضافة تابع fetchSingleCompany(BuildContext context, int companyId) إلى AdminCompanyProvider و ApiService
      // For now, simulate fetching from the list or show error if not found
      Company? fetchedCompany = adminCompanyProvider.companies.firstWhereOrNull((c) => c.companyId == widget.companyId);

      if (fetchedCompany != null) {
        setState(() {
          _company = fetchedCompany;
          _companyError = null;
        });
      } else {
        // Fallback: حاول جلب القائمة مرة أخرى
        await adminCompanyProvider.fetchAllCompanies(context);
        fetchedCompany = adminCompanyProvider.companies.firstWhereOrNull((c) => c.companyId == widget.companyId);

        if (fetchedCompany != null) {
          setState(() { _company = fetchedCompany; _companyError = null; });
        } else {
          setState(() { _company = null; _companyError = 'الشركة بمعرف ${widget.companyId} غير موجودة.'; });
        }
        // TODO: الأفضل هو استخدام تابع fetchSingleCompany من AdminCompanyProvider
      }

      setState(() { _isLoading = false; });

    } on ApiException catch (e) {
      setState(() {
        _company = null;
        _companyError = 'فشل جلب تفاصيل الشركة: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _company = null;
        _companyError = 'فشل جلب تفاصيل الشركة: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // تابع لحذف الشركة
  Future<void> _deleteCompany() async {
    if (_company?.companyId == null) return; // لا يمكن الحذف بدون معرف

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف الشركة "${_company!.name ?? 'بدون اسم'}"؟'),
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; _companyError = null; }); // بداية التحميل
      final provider = Provider.of<AdminCompanyProvider>(context, listen: false);
      try {
        await provider.deleteCompany(context, _company!.companyId!); // استدعاء تابع الحذف
        // بعد النجاح، العودة إلى شاشة قائمة الشركات
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الشركة بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          e.errors!.forEach((field, messages) => print('$field: ${messages.join(", ")}'));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الشركة: ${e.toString()}')),
        );
      } finally {
        setState(() { _isLoading = false; }); // انتهاء التحميل
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إلا لحالة التحميل عند عمليات الحذف/التعديل
    // final adminCompanyProvider = Provider.of<AdminCompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_company?.name ?? 'تفاصيل الشركة'),
        actions: [
          if (_company != null) ...[ // عرض الأزرار فقط إذا تم جلب الشركة بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : () { // تعطيل الزر أثناء التحميل
                // الانتقال إلى شاشة تعديل شركة
                print('Edit Company Tapped for ID ${widget.companyId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditCompanyScreen(company: _company!), // <--- تمرير كائن الشركة للشاشة الجديدة
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteCompany, // تعطيل الزر أثناء التحميل
            ),
            // TODO: يمكن إضافة أزرار أو روابط لإدارة موارد هذه الشركة (وظائف، دورات)
             IconButton(icon: const Icon(Icons.work_outline), onPressed: () {
               // ... Navigate to AdminManagedJobsScreen(companyId: _company!.companyId!) ...
             })
          ],
        ],
      ),
      body: _isLoading && _company == null // حالة التحميل الأولية فقط
          ? const Center(child: CircularProgressIndicator())
          : _companyError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: ${_companyError!}'))
          : _company == null // بيانات غير موجودة بعد التحميل (وإذا لا يوجد خطأ، هذا يعني 404 من API)
          ? const Center(child: Text('الشركة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الشركة (مشابه لشاشة التفاصيل العامة، مع تفاصيل خاصة بالأدمن)
            Text(
              _company!.name ?? 'بدون اسم',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('معرف الشركة: ${_company!.companyId ?? 'غير متوفر'}', style: const TextStyle(fontSize: 14, color: Colors.grey)), // خاص بالأدمن
            Text('معرف المدير: ${_company!.userId ?? 'غير محدد'}', style: const TextStyle(fontSize: 14, color: Colors.grey)), // خاص بالأدمن
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
              Text(_company!.webSite!),
            ],
            // TODO: عرض روابط الوسائط

            const Divider(height: 24),

            // TODO: يمكن عرض قائمة بفرص العمل التابعة لهذه الشركة هنا
            // TODO: يمكن عرض قائمة بالدورات التابعة لهذه الشركة هنا
          ],
        ),
      ),
    );
  }
}

// TODO: أنشئ شاشات تفاصيل لجميع موارد الأدمن الأخرى (Company, Article, Job, Course)
// TODO: أنشئ شاشات إضافة/تعديل لجميع موارد الأدمن الأخرى (Company, Article, Job, Course, Skill, Group)
// TODO: أنشئ شاشة AdminCompanyRequestDetailScreen لعرض تفاصيل الطلب