import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart'; // لتحديث وحذف المستخدم
import '../models/user.dart'; // تأكد من المسار
import '../models/profile.dart'; // تأكد من المسار
import '../models/skill.dart'; // تأكد من المسار
import '../models/company.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException
// استيراد شاشة تعديل المستخدم
import 'edit_user_screen.dart'; // <--- تأكد من المسار


class AdminUserDetailScreen extends StatefulWidget {
  final int userId;

  const AdminUserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AdminUserDetailScreenState createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  User? _user; // لتخزين بيانات المستخدم الفردية
  String? _userError; // لتخزين خطأ جلب المستخدم
  bool _isLoading = false; // حالة تحميل خاصة بالشاشة عند جلب البيانات أو تنفيذ إجراء


  @override
  void initState() {
    super.initState();
    _fetchUser(); // جلب تفاصيل المستخدم عند تهيئة الشاشة
  }

  // تابع لجلب تفاصيل المستخدم المحدد
  Future<void> _fetchUser() async {
    setState(() { _isLoading = true; _userError = null; });
    final userProvider = Provider.of<AdminUserProvider>(context, listen: false);

    try {
      // البحث عن المستخدم في القائمة المحملة أولاً
      User? fetchedUser = ListUserExtension(userProvider.users).firstWhereOrNull((u) => u.userId == widget.userId);

      if (fetchedUser != null) {
        // إذا وجد المستخدم في القائمة، نستخدم بياناته
        setState(() {
          _user = fetchedUser;
          _userError = null;
        });
      } else {
        // إذا لم يتم العثور عليه في القائمة المحملة حالياً
        // الخيار الأفضل هو إضافة تابع fetchSingleUser(int userId) في AdminUserProvider
        // وداخل AdminUserProvider، يستخدم ApiService.fetchUser(token, userId)
        // For now, as a fallback: try to fetch the list again and find it, or just show error if not found.
        // Let's fetch the list again, which is not ideal for performance on large lists,
        // but works with the current AdminUserProvider structure.

        // يمكنك استبدال السطر التالي بتعليق TODO وتطلب إضافة fetchSingleUser
        await userProvider.fetchAllUsers(context); // <-- قد يكون غير فعال لقوائم كبيرة

        // ابحث مرة أخرى في القائمة بعد محاولة جلبها بالكامل
        fetchedUser = ListUserExtension(userProvider.users).firstWhereOrNull((u) => u.userId == widget.userId);

        if (fetchedUser != null) {
          setState(() {
            _user = fetchedUser;
            _userError = null;
          });
        } else {
          setState(() {
            _user = null;
            _userError = 'المستخدم بمعرف ${widget.userId} غير موجود في القائمة المحملة.';
          });
        }
        // TODO: الأفضل هو إضافة تابع fetchSingleUser(int userId) في AdminUserProvider و ApiService
      }

    } on ApiException catch (e) {
      setState(() {
        _user = null;
        _userError = e.message;
      });
    } catch (e) {
      setState(() {
        _user = null;
        _userError = 'فشل جلب بيانات المستخدم: ${e.toString()}';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // تابع لحذف المستخدم
  Future<void> _deleteUser() async {
    if (_user?.userId == null) return; // لا يمكن الحذف بدون معرف

    // TODO: إضافة AlertDialog للتأكيد قبل الحذف
    final confirmed = await showDialog<bool>( // عرض مربع حوار تأكيد
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف المستخدم ${_user!.username ?? _user!.firstName ?? ''}؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // إغلاق المربع وإرجاع false
              },
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // إغلاق المربع وإرجاع true
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      setState(() { _isLoading = true; _userError = null; }); // بداية التحميل

      final provider = Provider.of<AdminUserProvider>(context, listen: false);
      try {
        await provider.deleteUser(context, _user!.userId!); // استدعاء تابع الحذف
        // بعد النجاح، العودة إلى شاشة قائمة المستخدمين
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستخدم بنجاح.')),
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
          SnackBar(content: Text('فشل حذف المستخدم: ${e.toString()}')),
        );
      } finally {
        setState(() { _isLoading = false; }); // انتهاء التحميل
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // لا نحتاج للاستماع للـ provider هنا إلا إذا كان له حالة تحميل خاصة بعمليات التعديل/الحذف
    // final userProvider = Provider.of<AdminUserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.username ?? 'تفاصيل المستخدم'),
        actions: [
          if (_user != null) ...[ // عرض الأزرار فقط إذا تم جلب المستخدم بنجاح
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : () { // تعطيل الزر أثناء التحميل
                // الانتقال إلى شاشة تعديل المستخدم
                print('Edit User Tapped for ID ${widget.userId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditUserScreen(user: _user!), // <--- تمرير كائن المستخدم للشاشة الجديدة
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteUser, // تعطيل الزر أثناء التحميل
            ),
          ],
        ],
      ),
      body: _isLoading && _user == null // حالة التحميل الأولية فقط
          ? const Center(child: CircularProgressIndicator())
          : _userError != null // خطأ جلب البيانات
          ? Center(child: Text('Error: $_userError'))
          : _user == null // بيانات غير موجودة بعد التحميل
          ? const Center(child: Text('المستخدم غير موجود.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل المستخدم (مشابه لشاشة ملف المستخدم الشخصي، ولكن للأدمن)
            Text('الاسم: ${_user!.firstName ?? ''} ${_user!.lastName ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('اسم المستخدم: ${_user!.username ?? ''}'),
            Text('البريد الإلكتروني: ${_user!.email ?? ''}'),
            Text('نوع الحساب: ${_user!.type ?? ''}'),
            Text('الحالة: ${_user!.status ?? ''}'),
            if (_user!.phone != null) Text('رقم الهاتف: ${_user!.phone!}'),
            // ... عرض باقي التفاصيل مثل created_at, updated_at

            const Divider(height: 24),

            // بيانات الملف الشخصي (من user.profile)
            const Text('بيانات الملف الشخصي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_user!.profile == null)
              const Text('لا توجد بيانات ملف شخصي متاحة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (_user!.profile != null) ...[
              if (_user!.profile!.university != null) Text('الجامعة: ${_user!.profile!.university!}'),
              if (_user!.profile!.gpa != null) Text('المعدل التراكمي: ${_user!.profile!.gpa!}'),
              if (_user!.profile!.personalDescription != null) ...[
                const Text('نبذة شخصية:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_user!.profile!.personalDescription!),
              ],
              if (_user!.profile!.technicalDescription != null) ...[
                const Text('نبذة اختصاصية:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_user!.profile!.technicalDescription!),
              ],
              if (_user!.profile!.gitHyperLink != null) ...[
                const Text('رابط GitHub:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_user!.profile!.gitHyperLink!),
              ],
            ],
            const Divider(height: 24),

            // المهارات (من user.skills)
            const Text('المهارات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_user!.skills == null || _user!.skills!.isEmpty)
              const Text('لا توجد مهارات مرتبطة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (_user!.skills != null && _user!.skills!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _user!.skills!.map((skill) => Chip(
                  label: Text('${skill.name ?? 'غير معروف'} (${skill.pivot?.stage ?? 'غير محدد'})'),
                )).toList(),
              ),
            const Divider(height: 24),

            // الشركة (من user.company)
            const Text('الشركة (إذا كان مدير شركة):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_user!.company == null)
              const Text('المستخدم ليس مرتبطاً بشركة.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (_user!.company != null) ...[
              Text('اسم الشركة: ${_user!.company!.name ?? 'غير معروف'}'),
              // ... عرض باقي بيانات الشركة ...
            ],
            const Divider(height: 24),

            // TODO: عرض طلبات التوظيف (MyApplications) لهذا المستخدم إذا كنت تحملها
            // TODO: عرض تسجيلات الدورات (MyEnrollments) لهذا المستخدم إذا كنت تحملها
            // TODO: عرض فرص العمل التي أنشأها (CreatedJobs) لهذا المستخدم إذا كان مدير أو أدمن
            // TODO: عرض الدورات التي أنشأها (CreatedCourses) لهذا المستخدم إذا كان مدير أو استشاري أو أدمن
            // TODO: عرض المقالات التي أنشأها (CreatedArticles) لهذا المستخدم إذا كان استشاري أو أدمن
          ],
        ),
      ),
    );
  }

// الامتداد لتوفير firstWhereOrNull على List<User>
// تأكد أن هذا الامتداد معرف في هذا الملف أو في ملف يتم استيراده هنا
// إذا استخدمت حزمة collection، يمكنك استيرادها واستخدام التابع منها
}

// Simple extension for List<User>
extension ListUserExtension on List<User> {
  User? firstWhereOrNull(bool Function(User) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}