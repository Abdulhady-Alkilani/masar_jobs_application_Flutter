// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- 1. استيراد جميع الـ Providers ---
// (هذه القائمة كاملة كما هي في ملفك)
import 'package:masar_jobs/providers/auth_provider.dart';
import 'package:masar_jobs/providers/admin_article_provider.dart';
import 'package:masar_jobs/providers/admin_company_provider.dart';
import 'package:masar_jobs/providers/admin_company_requests_provider.dart';
import 'package:masar_jobs/providers/admin_course_provider.dart';
import 'package:masar_jobs/providers/admin_group_provider.dart';
import 'package:masar_jobs/providers/admin_job_provider.dart';
import 'package:masar_jobs/providers/admin_skill_provider.dart';
import 'package:masar_jobs/providers/admin_user_provider.dart';
import 'package:masar_jobs/providers/consultant_article_provider.dart';
import 'package:masar_jobs/providers/course_enrollees_provider.dart';
import 'package:masar_jobs/providers/job_applicants_provider.dart';
import 'package:masar_jobs/providers/managed_company_provider.dart';
import 'package:masar_jobs/providers/managed_job_opportunity_provider.dart';
import 'package:masar_jobs/providers/managed_training_course_provider.dart';
import 'package:masar_jobs/providers/my_applications_provider.dart';
import 'package:masar_jobs/providers/my_enrollments_provider.dart';
import 'package:masar_jobs/providers/public_article_provider.dart';
import 'package:masar_jobs/providers/public_company_provider.dart';
import 'package:masar_jobs/providers/public_group_provider.dart';
import 'package:masar_jobs/providers/public_job_opportunity_provider.dart';
import 'package:masar_jobs/providers/public_skill_provider.dart';
import 'package:masar_jobs/providers/public_training_course_provider.dart';
import 'package:masar_jobs/providers/recommendation_provider.dart';

// --- 2. استيراد الشاشة الرئيسية وحزمة دعم اللغة ---
import 'screens/wrapper_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  // التأكد من تهيئة Flutter قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 3. تعريف الثيم الجمالي للتطبيق ---
    final cosmicTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo', // تأكد من إضافة هذا الخط في ملف pubspec.yaml

      // --- الألوان الرئيسية ---
      primaryColor: const Color(0xFF303F9F), // بنفسجي-أزرق داكن (Indigo)
      scaffoldBackgroundColor: const Color(0xFFF8F7FF), // لون خلفية هادئ ومشرق

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF303F9F),
        primary: const Color(0xFF303F9F),
        secondary: const Color(0xFFFF4081), // وردي زاهي للتمييز (Accent)
        background: const Color(0xFFF8F7FF),
        surface: Colors.white, // لون البطاقات
        onPrimary: Colors.white, // لون النص فوق اللون الأساسي
        onSecondary: Colors.white,
        onError: Colors.white,
        error: const Color(0xFFD32F2F), // أحمر للأخطاء
      ),

      // --- تخصيص شريط التطبيق (AppBar) ---
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // شفاف ليتناسب مع التصاميم الحديثة
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF303F9F)), // لون أيقونة القائمة
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Color(0xFF303F9F),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // --- تخصيص الأزرار الرئيسية ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF303F9F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // --- تخصيص شريط التنقل السفلي ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF303F9F),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
      ),
    );

    // --- 4. استخدام MultiProvider لتقديم كل الحالات (States) للتطبيق ---
    return MultiProvider(
      providers: [
        // هنا قائمة بكل الـ Providers التي يحتاجها تطبيقك
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PublicArticleProvider()),
        ChangeNotifierProvider(create: (_) => PublicJobOpportunityProvider()),
        ChangeNotifierProvider(create: (_) => PublicTrainingCourseProvider()),
        ChangeNotifierProvider(create: (_) => PublicCompanyProvider()),
        ChangeNotifierProvider(create: (_) => PublicGroupProvider()),
        ChangeNotifierProvider(create: (_) => PublicSkillProvider()),
        ChangeNotifierProvider(create: (_) => MyApplicationsProvider()),
        ChangeNotifierProvider(create: (_) => MyEnrollmentsProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => ConsultantArticleProvider()),
        ChangeNotifierProvider(create: (_) => ManagedJobOpportunityProvider()),
        ChangeNotifierProvider(create: (_) => ManagedTrainingCourseProvider()),
        ChangeNotifierProvider(create: (_) => ManagedCompanyProvider()),
        ChangeNotifierProvider(create: (_) => JobApplicantsProvider()),
        ChangeNotifierProvider(create: (_) => CourseEnrolleesProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => AdminSkillProvider()),
        ChangeNotifierProvider(create: (_) => AdminGroupProvider()),
        ChangeNotifierProvider(create: (_) => AdminCompanyProvider()),
        ChangeNotifierProvider(create: (_) => AdminArticleProvider()),
        ChangeNotifierProvider(create: (_) => AdminJobProvider()),
        ChangeNotifierProvider(create: (_) => AdminCourseProvider()),
        ChangeNotifierProvider(create: (_) => AdminCompanyRequestsProvider()),
      ],
      child: MaterialApp(
        title: 'مسار',
        debugShowCheckedModeBanner: false,

        // --- 5. تطبيق الثيم وتفعيل دعم اللغة العربية ---
        theme: cosmicTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'AE'), // تحديد اللغة العربية كلغة مدعومة
        ],
        locale: const Locale('ar', 'AE'), // جعل اللغة العربية هي اللغة الافتراضية للتطبيق

        // --- 6. تحديد الشاشة الأولى التي ستظهر للمستخدم ---
        home: const WrapperScreen(),
      ),
    );
  }
}