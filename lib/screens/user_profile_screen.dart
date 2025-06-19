import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // لحالة المستخدم الحالي
import '../models/user.dart';
import '../models/profile.dart'; // تأكد من المسار
import '../models/skill.dart'; // تأكد من المسار
import '../models/company.dart'; // تأكد من المسار
// لا نحتاج استيراد ملفات اللغة المولّدة لأننا لا نستخدمها حالياً
// import '../generated/l10n.dart';


// استيراد شاشات أخرى لربطها من هنا (اختياري)
import 'my_applications_screen.dart';
import 'my_enrollments_screen.dart';
import 'recommendations_screen.dart';
import 'consultant_articles_screen.dart'; // للمستشار
import 'managed_jobs_list_screen.dart'; // للمدير (وظائف)
import 'managed_courses_list_screen.dart'; // للمدير (دورات)
import 'admin_panel_screen.dart'; // للأدمن

// استيراد شاشات التعديل
import 'edit_user_profile_screen.dart'; // <--- شاشة تعديل الملف الشخصي (للخريج/الاستشاري)
import 'edit_user_skills_screen.dart'; // شاشة تعديل المهارات (للخريج/الاستشاري)
import 'edit_company_screen.dart'; // <--- تأكد من مسار EditCompanyScreen (لتعديل الشركة للمدير)
import 'create_edit_user_screen.dart'; // <--- تأكد من مسار شاشة تعديل المستخدم للأدمن (نستخدمها هنا لتعديل الأدمن لنفسه)

// قد تحتاج لـ url_launcher لفتح الروابط مثل GitHub أو موقع الشركة
// import 'package:url_launcher/url_launcher.dart';


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  // تابع لفتح رابط URL (يحتاج url_launcher)
  /*
   Future<void> _launchUrl(BuildContext context, String urlString) async {
     try {
       final Uri url = Uri.parse(urlString);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $url');
        }
     } catch (e) {
       print('Error launching URL: $e');
       // استخدم نصاً ثابتاً أو قم بتعريف نصوص الأخطاء محلياً إذا لم تكن تستخدم Localization
       ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('فشلت العملية: ${e.toString()}')), // نص ثابت أو متغير
       );
     }
   }
   */

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة AuthProvider (خاصة User)
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      // هذا لا ينبغي أن يحدث إذا تم التعامل مع المصادقة بشكل صحيح في WrapperScreen
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')), // نص ثابت
        body: const Center(child: Text('المستخدم غير مسجل الدخول.')), // نص ثابت
      );
    }

    // تحديد نوع المستخدم
    bool isAdmin = user.type == 'Admin';
    bool isCompanyManager = user.type == 'مدير شركة';
    bool isGraduate = user.type == 'خريج';
    bool isConsultant = user.type == 'خبير استشاري';

    return Scaffold(
        appBar: AppBar(
          title: const Text('ملفي الشخصي'), // نص ثابت
          actions: [
            // زر تعديل المستخدم الأساسي (للأدمن)
            if (isAdmin) // يظهر فقط للأدمن (لتعديل نفسه)
              IconButton(
                icon: const Icon(Icons.settings), // أيقونة مناسبة للمستخدم
                tooltip: 'تعديل بيانات المستخدم', // نص ثابت
                onPressed: () {
                  print('Edit User Data Tapped for Admin');
                  // نمرر كائن المستخدم الحالي لشاشة التعديل
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditUserScreen(user: user))); // <--- الانتقال لشاشة تعديل المستخدم كأدمن
                },
              ),

            // زر تعديل الشركة (لمدير الشركة)
            if (isCompanyManager && user.company != null) // يظهر فقط لمدير الشركة ولديه شركة
              IconButton(
                icon: const Icon(Icons.business), // أيقونة مناسبة للشركة
                tooltip: 'تعديل الشركة', // نص ثابت
                onPressed: () {
                  print('Edit Company Tapped for Manager');
                  // نمرر كائن الشركة لشاشة التعديل
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditCompanyScreen(company: user.company!))); // <--- الانتقال لشاشة تعديل الشركة

                },
              ),

            // زر تعديل الملف الشخصي (للخريج/الاستشاري)
            // وزر تعديل المهارات (للخريج/الاستشاري)
            // تم وضعهما الآن في جسم الشاشة بجوار الأقسام المعنية مباشرةً.
            // إذا أردتهما في الـ AppBar، قم بإزالة الأزرار من جسم الشاشة وأعدها هنا مع منطق الـ if المناسب.

          ],
        ),
        body: authProvider.isLoading // إذا كان الـ AuthProvider يحمل بيانات (مثل إعادة جلب المستخدم بعد التحديث)
            ? const Center(child: CircularProgressIndicator())
            : authProvider.error != null // إذا كان الـ AuthProvider فيه خطأ
            ? Center(child: Text('Error loading user data: ${authProvider.error ?? 'Unknown error'}')) // نص ثابت + متغير
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // بيانات المستخدم الأساسية
                _buildSectionTitle('بيانات المستخدم الأساسية'), // نص ثابت
            _buildInfoRow('الاسم:', '${user.firstName ?? ''} ${user.lastName ?? ''}'), // نص ثابت + متغير
            _buildInfoRow('اسم المستخدم:', user.username), // نص ثابت + متغير
            _buildInfoRow('البريد الإلكتروني:', user.email), // نص ثابت + متغير
            _buildInfoRow('نوع الحساب:', user.type), // نص ثابت + متغير
            _buildInfoRow('الحالة:', user.status), // نص ثابت + متغير
            if (user.phone != null && user.phone!.isNotEmpty) _buildInfoRow('رقم الهاتف:', user.phone), // نص ثابت + متغير
    // TODO: عرض الصورة إذا كانت موجودة (يحتاج إلى URL كامل للصورة)
    // if (user.photo != null && user.photo!.isNotEmpty)
    //   _buildPhotoWidget(context, 'http://127.0.0.1:8000${user.photo!}'),


    const Divider(height: 32),

    // بيانات الملف الشخصي (من user.profile) - يعرض فقط إذا كان موجوداً ومناسباً للنوع
    Row( // صف لعرض عنوان القسم مع زر التعديل
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    _buildSectionTitle('بيانات الملف الشخصي'), // نص ثابت
    // زر تعديل الملف الشخصي (للخريج/الاستشاري) - بجوار العنوان
    if (isGraduate || isConsultant) // يظهر فقط للخريج والاستشاري
    IconButton(
    icon: const Icon(Icons.edit, color: Colors.blue), // أيقونة تعديل
    tooltip: 'تعديل الملف الشخصي', // نص ثابت
    onPressed: () {
    print('Edit Profile Tapped for Graduate/Consultant');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditUserProfileScreen())); // <--- الانتقال لشاشة تعديل الملف الشخصي
    },
    ),
    ],
    ),
    if (!isGraduate && !isConsultant) // غير متاح لغير الخريج والاستشاري
    _buildInfoRow(null, 'غير متاح لهذا النوع من الحسابات.') // نص ثابت
    else if (user.profile == null)
    _buildInfoRow(null, 'لا توجد بيانات ملف شخصي متاحة.') // نص ثابت
    else if (user.profile != null) ...[ // عرض بيانات الملف الشخصي إذا كان موجوداً
    if (user.profile!.university != null && user.profile!.university!.isNotEmpty) _buildInfoRow('الجامعة:', user.profile!.university), // نص ثابت + متغير
    if (user.profile!.gpa != null && user.profile!.gpa!.isNotEmpty) _buildInfoRow('المعدل التراكمي:', user.profile!.gpa), // نص ثابت + متغير
    if (user.profile!.personalDescription != null && user.profile!.personalDescription!.isNotEmpty)
    _buildMultiLineInfo('نبذة شخصية:', user.profile!.personalDescription!), // نص ثابت + متغير
    if (user.profile!.technicalDescription != null && user.profile!.technicalDescription!.isNotEmpty)
    _buildMultiLineInfo('نبذة اختصاصية:', user.profile!.technicalDescription!), // نص ثابت + متغير
    if (user.profile!.gitHyperLink != null && user.profile!.gitHyperLink!.isNotEmpty)
    _buildInfoRow('رابط GitHub:', user.profile!.gitHyperLink!), // TODO: اجعله clickable

    ],
    const Divider(height: 32),

    // المهارات (من user.skills) - يعرض فقط إذا كانت موجودة ومناسبة للنوع
    Row( // صف لعرض عنوان القسم مع زر التعديل
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    _buildSectionTitle('المهارات'), // نص ثابت
    // زر تعديل المهارات (للخريج/الاستشاري) - بجوار العنوان
    if (isGraduate || isConsultant) // يظهر فقط للخريج والاستشاري
    IconButton(
    icon: const Icon(Icons.edit, color: Colors.blue), // أيقونة تعديل
    tooltip: 'تعديل المهارات', // نص ثابت
    onPressed: () {
    print('Edit Skills Tapped');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditUserSkillsScreen())); // <--- الانتقال لشاشة تعديل المهارات
    },
    ),
    ],
    ),
    if (!isGraduate && !isConsultant) // غير متاح لغير الخريج والاستشاري
    _buildInfoRow(null, 'غير متاح لهذا النوع من الحسابات.')// نص ثابت
    else if (user.skills == null || user.skills!.isEmpty)
    _buildInfoRow(null, 'لم يتم إضافة مهارات بعد.')


    // نص ثابت
    else if (user.skills != null && user.skills!.isNotEmpty)
    Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Wrap( // لعرض المهارات كـ chips
    spacing: 8.0,
    runSpacing: 4.0,
    children: user.skills!.map((skill) => Chip(
    label: Text('${skill.name ?? "غير معروف"} (${skill.pivot?.stage ?? "غير محدد"})'), // عرض المستوى هنا
    backgroundColor: Colors.blue.shade100,
    )).toList(),
    ),
    ),
    // زر تعديل المهارات (يعرض فقط إذا كان نوع الحساب مناسباً)
    // تم نقله هنا ليكون بجوار قسم المهارات.
    //  if (isGraduate || isConsultant) // عرض الزر للخريج والاستشاري
    //    Padding(
    //      padding: const EdgeInsets.only(top: 16.0),
    //      child: ElevatedButton(
    //        onPressed: () { ... },
    //        child: const Text('تعديل المهارات'),
    //      ),
    //    ),
    const Divider(height: 32),


    // بيانات الشركة (للمدير) - يعرض فقط إذا كان مدير شركة ولديه شركة مرتبطة
    if (isCompanyManager) ...[
    Row( // صف لعرض عنوان القسم مع زر التعديل
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    _buildSectionTitle('الشركة المرتبطة'), // نص ثابت
    // زر تعديل الشركة (لمدير الشركة) - بجوار العنوان
    if (user.company != null) // يظهر فقط إذا لديه شركة
    IconButton(
    icon: const Icon(Icons.edit, color: Colors.blue), // أيقونة تعديل
    tooltip: 'تعديل الشركة', // نص ثابت
    onPressed: () {
    print('Edit Company Tapped for Manager');
    // نمرر كائن الشركة لشاشة التعديل
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditCompanyScreen(company: user.company!))); // <--- الانتقال لشاشة تعديل الشركة
    },
    ),
    ],
    ),

    if (user.company == null)
    _buildInfoRow(null, 'لا توجد شركة مرتبطة بحسابك.'), // نص ثابت
    if (user.company != null) ...[
    _buildInfoRow('اسم الشركة:', user.company!.name), // نص ثابت + متغير
    if (user.company!.status != null && user.company!.status!.isNotEmpty) _buildInfoRow('حالة الشركة:', user.company!.status), // نص ثابت + متغير
    // TODO: عرض المزيد من تفاصيل الشركة هنا
    // TODO: إضافة زر للانتقال لصفحة تفاصيل الشركة (إذا كانت هناك صفحة تفاصيل كاملة)
    ],
    const Divider(height: 32),
    ],


    // روابط سريعة لشاشات أخرى خاصة بالمستخدم
    // يمكن إضافة عنوان للروابط السريعة هنا إذا لزم الأمر
    // if (isGraduate || isConsultant || isCompanyManager || isAdmin)
    //   _buildSectionTitle('روابط سريعة'), // نص ثابت

    if (isGraduate) ...[ // روابط خاصة بالخريج
    ListTile(
    leading: const Icon(Icons.work),
    title: const Text('طلبات التوظيف الخاصة بي'), // نص ثابت
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyApplicationsScreen()));
    },
    ),
    ListTile(
    leading: const Icon(Icons.school),
    title: const Text('تسجيلات الدورات الخاصة بي'), // نص ثابت
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyEnrollmentsScreen()));
    },
    ),
    ListTile(
    leading: const Icon(Icons.recommend),
    title: const Text('التوصيات'), // نص ثابت
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendationsScreen()));
    },
    ),
    ],

    if (isConsultant) ...[ // روابط خاصة بالاستشاري (مثلاً مقالاته)
    ListTile(
    leading: const Icon(Icons.article),
    title: const Text('مقالاتي'), // نص ثابت
    onTap: () {
    print('My Articles Tapped');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsultantArticlesScreen()));
    },
    ),
    ],

    if (isCompanyManager) ...[ // روابط خاصة بمدير الشركة (مثلاً إدارة الوظائف والدورات من هنا)
    ListTile(
    leading: const Icon(Icons.work_outline),
    title: const Text('إدارة فرص العمل'), // نص ثابت
    onTap: () {
    print('Manage My Jobs Tapped');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedJobsListScreen()));
    },
    ),
    ListTile(
    leading: const Icon(Icons.menu_book_outlined),
    title: const Text('إدارة الدورات'), // نص ثابت
    onTap: () {
    print('Manage My Courses Tapped');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagedCoursesListScreen()));
    },
    ),
    ],

    if (isAdmin) ...[ // رابط خاص بالأدمن (لوحة التحكم)
    ListTile(
    leading: const Icon(Icons.admin_panel_settings),
    title: const Text('لوحة تحكم الأدمن'), // نص ثابت
    onTap: () {
    print('Admin Panel Tapped');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
    },
    ),
    ],

    // TODO: إضافة أقسام أخرى للملف الشخصي بناءً على نوع المستخدم (مثلاً، الموارد التي أنشأها الأدمن)
    // TODO: عرض بيانات أخرى للمستخدم (مثل created_at, updated_at)
    ],
    ),
    ),
    );
  }


  // --- توابع مساعدة لبناء الواجهة ---

  // تابع لبناء عنوان قسم مع إمكانية إضافة Widget في النهاية (مثل زر التعديل)
  Widget _buildSectionTitle(String title, {Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row( // استخدام Row للسماح بوضع زر التعديل بجوار العنوان
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (trailingWidget != null) // عرض الـ Widget الإضافي (زر التعديل) إذا تم تمريره
            trailingWidget,
        ],
      ),
    );
  }

  // تابع لبناء صف لعرض معلومة بسيطة (Label: Value)
  Widget _buildInfoRow(String? label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // تابع لبناء صف لعرض معلومة متعددة الأسطر (Label: Multi-line Value)
  Widget _buildMultiLineInfo(String? label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

// TODO: تابع لبناء Widget لعرض صورة (إذا كانت موجودة)
/*
   Widget _buildPhotoWidget(BuildContext context, String? photoUrl) {
       if (photoUrl == null || photoUrl.isEmpty) return const SizedBox.shrink();
       // بناء Widget الصورة باستخدام Image.network
       return Padding(
         padding: const EdgeInsets.symmetric(vertical: 16.0),
         child: Image.network(
           'http://127.0.0.1:8000$photoUrl', // تأكد من URL الأساسي للصور
           fit: BoxFit.cover,
           errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80), // أيقونة عند فشل التحميل
         ),
       );
   }
   */

}

// Simple extension for List<Article> if not available elsewhere or using collection package
// Keep the extension if it's used here or remove if not.
/*
extension ListArticleExtension on List<Article> {
  Article? firstWhereOrNull(bool Function(Article) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
*/