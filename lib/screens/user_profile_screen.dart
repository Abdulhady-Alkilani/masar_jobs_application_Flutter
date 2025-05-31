import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // لحالة المستخدم الحالي
import '../models/user.dart';
import '../models/profile.dart'; // تأكد من الاستيراد
import '../models/skill.dart'; // تأكد من الاستيراد
// استيراد شاشات أخرى لربطها من هنا (اختياري)
import 'my_applications_screen.dart';
import 'my_enrollments_screen.dart';
import 'recommendations_screen.dart';
// استيراد شاشات TODO التي سننشئها
import 'edit_user_profile_screen.dart'; // <--- تأكد من المسار
import 'edit_user_skills_screen.dart'; // <--- تأكد من المسار


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: const Center(child: Text('المستخدم غير مسجل الدخول.')),
      );
    }

    // يمكن استخدام Consumer هنا للاستماع فقط لجزء معين (مثل Profile)
    // لكن Provider.of<AuthProvider> مع listen: false كافية إذا كنا فقط نعرض البيانات الأولية المحملة
    // وإذا أردنا عرض بيانات من providers أخرى (مثل طلبات التوظيف)، سنستخدم Consumer أو Provider.of لها هنا

    return Scaffold(
        appBar: AppBar(
          title: const Text('ملفي الشخصي'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // الانتقال إلى شاشة تعديل الملف الشخصي
                print('Edit Profile Tapped');
                // تأكد أن المستخدم ليس Admin لأنه قد لا يملك Profile
                if (user.type != 'Admin') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditUserProfileScreen())); // <--- الانتقال لشاشة التعديل
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الأدمن لا يمتلك ملفاً شخصياً تقليدياً للتعديل.')),
                  );
                }
              },
            ),
          ],
        ),
        body: authProvider.isLoading // إذا كان الـ AuthProvider يحمل بيانات (مثلاً إعادة جلب المستخدم بعد التحديث)
            ? const Center(child: CircularProgressIndicator())
            : authProvider.error != null // إذا كان الـ AuthProvider فيه خطأ
            ? Center(child: Text('Error loading user data: ${authProvider.error ?? "Unknown error"}')) // <--- تصحيح عرض الخطأ
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
            // بيانات المستخدم الأساسية
            Text('الاسم: ${user.firstName ?? ''} ${user.lastName ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('اسم المستخدم: ${user.username ?? ''}'),
            Text('البريد الإلكتروني: ${user.email ?? ''}'),
            Text('نوع الحساب: ${user.type ?? ''}'),
            if (user.phone != null) Text('رقم الهاتف: ${user.phone!}'),
    // عرض الصورة إذا كانت موجودة (يحتاج إلى URL كامل للصورة)
    // if (user.photo != null && user.photo!.isNotEmpty)
    //   Padding(
    //     padding: const EdgeInsets.symmetric(vertical: 16.0),
    //     child: Image.network('http://127.0.0.1:8000${user.photo!}', fit: BoxFit.cover),
    //   ),
    const Divider(height: 24),

    // بيانات الملف الشخصي (من user.profile)
    const Text('بيانات الملف الشخصي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    if (user.type == 'Admin' || user.type == 'مدير شركة') // Admin/Manager might not have a profile
    const Text('غير متاح لهذا النوع من الحسابات.', style: TextStyle(fontStyle: FontStyle.italic))
    else if (user.profile == null)
    const Text('لا توجد بيانات ملف شخصي متاحة.', style: TextStyle(fontStyle: FontStyle.italic)),
    if (user.profile != null && user.type != 'Admin' && user.type != 'مدير شركة') ...[ // عرض البيانات فقط إذا كان هناك Profile ومناسب لنوع الحساب
    if (user.profile!.university != null) Text('الجامعة: ${user.profile!.university!}'),
    if (user.profile!.gpa != null) Text('المعدل التراكمي: ${user.profile!.gpa!}'),
    if (user.profile!.personalDescription != null) ...[
    const Text('نبذة شخصية:', style: TextStyle(fontWeight: FontWeight.bold)),
    Text(user.profile!.personalDescription!),
    ],
    if (user.profile!.technicalDescription != null) ...[
    const Text('نبذة اختصاصية:', style: TextStyle(fontWeight: FontWeight.bold)),
    Text(user.profile!.technicalDescription!),
    ],
    if (user.profile!.gitHyperLink != null) ...[
    const Text('رابط GitHub:', style: TextStyle(fontWeight: FontWeight.bold)),
    // يمكن إضافة زر لفتح الرابط باستخدام url_launcher
    Text(user.profile!.gitHyperLink!),
    ],
    ],
    const Divider(height: 24),

    // المهارات (من user.skills)
    const Text('المهارات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    if (user.type == 'Admin' || user.type == 'مدير شركة') // Admin/Manager might not have skills
    const Text('غير متاح لهذا النوع من الحسابات.', style: TextStyle(fontStyle: FontStyle.italic))
    else if (user.skills == null || user.skills!.isEmpty)
    const Text('لم يتم إضافة مهارات بعد.', style: TextStyle(fontStyle: FontStyle.italic)),
    if (user.skills != null && user.skills!.isNotEmpty && user.type != 'Admin' && user.type != 'مدير شركة')
    Wrap( // لعرض المهارات كـ chips
    spacing: 8.0,
    runSpacing: 4.0,
    children: user.skills!.map((skill) => Chip(
    label: Text('${skill.name ?? 'غير معروف'} (${skill.pivot?.stage ?? 'غير محدد'})'), // عرض المستوى هنا
    backgroundColor: Colors.blue.shade100,
    )).toList(),
    ),
    const SizedBox(height: 16),
    // زر تعديل المهارات (عرضه فقط إذا كان نوع الحساب مناسباً)
    if (user.type == 'خريج' || user.type == 'خبير استشاري')
    ElevatedButton(
    onPressed: () {
    // الانتقال إلى شاشة تعديل المهارات
    print('Edit Skills Tapped');
    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditUserSkillsScreen())); // <--- الانتقال لشاشة تعديل المهارات
    },
    child: const Text('تعديل المهارات'),
    ),
    const Divider(height: 24),

    // روابط لشاشات أخرى خاصة بالمستخدم (اختياري هنا، يمكن أن تكون في HomeScreen)
    // هذه الروابط موجودة بالفعل في HomeScreen، لكن يمكنك تكرارها هنا إذا أردت
    if (user.type == 'خريج') ...[
    ListTile(
    leading: const Icon(Icons.work),
    title: const Text('طلبات التوظيف الخاصة بي'),
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyApplicationsScreen()));
    },
    ),
    ListTile(
    leading: const Icon(Icons.school),
    title: const Text('تسجيلات الدورات الخاصة بي'),
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyEnrollmentsScreen()));
    },
    ),
    ListTile(
    leading: const Icon(Icons.recommend),
    title: const Text('التوصيات'),
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendationsScreen()));
    },
    ),
    ],
    ],
    ),
    ),
    );
  }
}