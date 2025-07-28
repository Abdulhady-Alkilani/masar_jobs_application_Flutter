// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:masar_jobs/providers/theme_provider.dart';
import 'package:masar_jobs/screens/splash_screen.dart';
import 'package:masar_jobs/theme/app_theme.dart';
import 'package:provider/provider.dart';

// --- 1. استيراد جميع الـ Providers ---
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
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  // التأكد من تهيئة Flutter قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  // تحميل متغيرات البيئة
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 4. استخدام MultiProvider لتقديم كل الحالات (States) للتطبيق ---
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Masar Jobs',
            debugShowCheckedModeBanner: false,

            // --- 5. تطبيق الثيم وتفعيل دعم اللغة العربية ---
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
