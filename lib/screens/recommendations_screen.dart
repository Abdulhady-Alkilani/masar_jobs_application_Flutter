import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../models/job_opportunity.dart'; // لعرض الوظائف الموصى بها
import '../models/training_course.dart'; // لعرض الدورات الموصى بها
// استيراد شاشات تفاصيل لعرض تفاصيل التوصيات عند النقر
import 'job_opportunity_detail_screen.dart';
import 'training_course_detail_screen.dart';


class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    // جلب التوصيات عند الدخول للشاشة
    Provider.of<RecommendationProvider>(context, listen: false).fetchRecommendations(context);
  }

  @override
  Widget build(BuildContext context) {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final recommendations = recommendationProvider.recommendations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التوصيات لك'),
      ),
      body: recommendationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendationProvider.error != null
          ? Center(child: Text('Error: ${recommendationProvider.error}'))
          : recommendations == null // لم يتم جلب البيانات بعد
          ? const Center(child: Text('جاري جلب التوصيات...')) // أو رسالة أخرى
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('فرص العمل الموصى بها:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (recommendations.recommendedJobs == null || recommendations.recommendedJobs!.isEmpty)
              const Text('لا توجد فرص عمل موصى بها حالياً.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (recommendations.recommendedJobs != null)
              ListView.builder(
                shrinkWrap: true, // لجعل القائمة تأخذ الحجم الذي تحتاجه داخل العمود
                physics: const NeverScrollableScrollPhysics(), // لمنع تعارض التمرير مع SingleChildScrollView
                itemCount: recommendations.recommendedJobs!.length,
                itemBuilder: (context, index) {
                  final job = recommendations.recommendedJobs![index];
                  return ListTile(
                    title: Text(job.jobTitle ?? 'بدون عنوان'),
                    subtitle: Text('${job.type ?? ''} - ${job.site ?? ''}'),
                    onTap: () {
                      // الانتقال لتفاصيل الوظيفة
                      if (job.jobId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => JobOpportunityDetailScreen(jobId: job.jobId!)));
                      }
                    },
                  );
                },
              ),

            const Divider(height: 32),

            const Text('الدورات التدريبية الموصى بها:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (recommendations.recommendedCourses == null || recommendations.recommendedCourses!.isEmpty)
              const Text('لا توجد دورات موصى بها حالياً.', style: TextStyle(fontStyle: FontStyle.italic)),
            if (recommendations.recommendedCourses != null)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recommendations.recommendedCourses!.length,
                itemBuilder: (context, index) {
                  final course = recommendations.recommendedCourses![index];
                  return ListTile(
                    title: Text(course.courseName ?? 'بدون اسم'),
                    subtitle: Text('${course.site ?? ''} - ${course.stage ?? ''}'),
                    onTap: () {
                      // الانتقال لتفاصيل الدورة
                      if (course.courseId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TrainingCourseDetailScreen(courseId: course.courseId!)));
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}