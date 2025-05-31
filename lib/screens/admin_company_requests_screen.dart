import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_company_requests_provider.dart';
import '../models/company.dart';
import 'admin_company_request_detail_screen.dart';
// يمكن إضافة شاشة تفاصيل الشركة أو تفاصيل مدير الشركة من هنا

class AdminCompanyRequestsScreen extends StatefulWidget {
  const AdminCompanyRequestsScreen({Key? key}) : super(key: key);

  @override
  _AdminCompanyRequestsScreenState createState() => _AdminCompanyRequestsScreenState();
}

class _AdminCompanyRequestsScreenState extends State<AdminCompanyRequestsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<AdminCompanyRequestsProvider>(context, listen: false).fetchCompanyRequests(context);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<AdminCompanyRequestsProvider>(context, listen: false).fetchMoreCompanyRequests(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // تابع للموافقة على طلب
  Future<void> _approveRequest(int companyId) async {
    final provider = Provider.of<AdminCompanyRequestsProvider>(context, listen: false);
    try {
      await provider.approveRequest(context, companyId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة على الطلب بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الموافقة على الطلب: ${e.toString()}')),
      );
    }
  }

  // تابع لرفض طلب
  Future<void> _rejectRequest(int companyId) async {
    final provider = Provider.of<AdminCompanyRequestsProvider>(context, listen: false);
    try {
      await provider.rejectRequest(context, companyId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الطلب بنجاح.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفض الطلب: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final requestsProvider = Provider.of<AdminCompanyRequestsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الشركات الجديدة'),
      ),
      body: requestsProvider.isLoading && requestsProvider.companyRequests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : requestsProvider.error != null
          ? Center(child: Text('Error: ${requestsProvider.error}'))
          : requestsProvider.companyRequests.isEmpty
          ? const Center(child: Text('لا توجد طلبات معلقة حالياً.'))
          : ListView.builder(
        controller: _scrollController,
        itemCount: requestsProvider.companyRequests.length + (requestsProvider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == requestsProvider.companyRequests.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final request = requestsProvider.companyRequests[index];
          return ListTile(
            title: Text(request.name ?? 'اسم شركة غير معروف'),
            subtitle: Text('المقدم: ${request.user?.firstName ?? ''} ${request.user?.lastName ?? ''}'), // يعرض اسم المدير المقدم للطلب
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'موافقة',
                  onPressed: () {
                    if (request.companyId != null) {
                      _approveRequest(request.companyId!);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'رفض',
                  onPressed: () {
                    if (request.companyId != null) {
                      _rejectRequest(request.companyId!);
                    }
                  },
                ),
              ],
            ),

            onTap: () {
              // عندما ينقر المستخدم على هذا ListTile بالذات:
              // هذا هو المكان الذي ننتقل فيه إلى شاشة التفاصيل
              // ونمرر بيانات طلب الشركة الذي تم النقر عليه.

              // TODO: الانتقال إلى شاشة تفاصيل طلب الشركة (AdminCompanyRequestDetailScreen)
              // يمكن عرض تفاصيل الشركة بشكل أوسع ومعلومات المدير المقدم للطلب
              print('Company Request Tapped for ID ${request.companyId}');

              // تأكد من أن companyId ليس null قبل الانتقال
              if (request.companyId != null) {
                // هذا هو الجزء الذي يربط النقر بالشاشة الأخرى
                Navigator.push( // نستخدم Navigator للانتقال
                  context, // Context ضروري للملاحة
                  MaterialPageRoute( // نحدد نوع المسار
                    builder: (context) => AdminCompanyRequestDetailScreen( // نحدد الشاشة التي سنذهب إليها
                      companyRequest: request, // <--- هذا هو الجزء الأهم: نمرر كائن 'request' الحالي كـ parameter اسمه 'companyRequest' للشاشة الجديدة
                    ),
                  ),
                );
              } else {
                // رسالة خطأ إذا لم يكن هناك معرف للشركة (حالة غير متوقعة لطلب صالح)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('معرف الطلب غير متاح.')),
                );
              }},
          );
        },
      ),
    );
  }
}

// TODO: أنشئ شاشات تفاصيل لجميع موارد الأدمن الأخرى (Companies, Articles, Jobs, Courses)
// TODO: أنشئ شاشات إضافة/تعديل لجميع موارد الأدمن الأخرى (Companies, Articles, Jobs, Courses)
// TODO: أنشئ شاشة AdminCompanyRequestDetailScreen لعرض تفاصيل الطلب (يمكن أن تحتوي على أزرار الموافقة والرفض أيضاً)