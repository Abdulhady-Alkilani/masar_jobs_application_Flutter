import 'package:flutter/material.dart';
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
import 'package:masar_jobs/providers/public_company_provider.dart';
import 'package:masar_jobs/providers/public_group_provider.dart';
import 'package:masar_jobs/providers/public_job_opportunity_provider.dart';
import 'package:masar_jobs/providers/public_skill_provider.dart';
import 'package:masar_jobs/providers/public_training_course_provider.dart';
import 'package:masar_jobs/providers/recommendation_provider.dart';
import 'package:provider/provider.dart';
// ... import all providers ...
import 'providers/auth_provider.dart';
import 'providers/public_article_provider.dart';
// ...
import 'screens/wrapper_screen.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // استخدم MultiProvider لتقديم أكثر من Provider
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => PublicArticleProvider()),
        ChangeNotifierProvider(create: (context) => PublicJobOpportunityProvider()),
        ChangeNotifierProvider(create: (context) => PublicTrainingCourseProvider()),
        ChangeNotifierProvider(create: (context) => PublicCompanyProvider()),
        ChangeNotifierProvider(create: (context) => PublicGroupProvider()),
        ChangeNotifierProvider(create: (context) => PublicSkillProvider()),
        ChangeNotifierProvider(create: (context) => MyApplicationsProvider()),
        ChangeNotifierProvider(create: (context) => MyEnrollmentsProvider()),
        ChangeNotifierProvider(create: (context) => RecommendationProvider()),
        ChangeNotifierProvider(create: (context) => ManagedJobOpportunityProvider()),
        ChangeNotifierProvider(create: (context) => ManagedTrainingCourseProvider()),
        ChangeNotifierProvider(create: (context) => ManagedCompanyProvider()),
        ChangeNotifierProvider(create: (context) => JobApplicantsProvider()),
        ChangeNotifierProvider(create: (context) => CourseEnrolleesProvider()),
        ChangeNotifierProvider(create: (context) => ConsultantArticleProvider()),
        ChangeNotifierProvider(create: (context) => AdminUserProvider()),
        ChangeNotifierProvider(create: (context) => AdminSkillProvider()),
        ChangeNotifierProvider(create: (context) => AdminGroupProvider()),
        ChangeNotifierProvider(create: (context) => AdminCompanyProvider()),
        ChangeNotifierProvider(create: (context) => AdminArticleProvider()),
        ChangeNotifierProvider(create: (context) => AdminJobProvider()),
        ChangeNotifierProvider(create: (context) => AdminCourseProvider()),
        ChangeNotifierProvider(create: (context) => AdminCompanyRequestsProvider()),
        // ... add other providers here ...
      ],
      child: MaterialApp(
        title: 'Masar Jobs App',


        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: const WrapperScreen(),
      ),
    );
  }
}