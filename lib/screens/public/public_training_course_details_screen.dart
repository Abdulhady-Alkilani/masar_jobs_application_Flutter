// lib/screens/public_views/public_training_course_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
// ستحتاج مكتبة url_launcher لفتح الرابط إذا كان موجوداً
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart'; // لاستخدام launchUrlString

import '../../models/training_course.dart';
import '../../providers/auth_provider.dart';
import '../../providers/my_enrollments_provider.dart';
import '../../providers/public_training_course_provider.dart';
import '../../services/api_service.dart'; // لاستخدام ApiException
// TODO: قد تحتاج استيراد AuthProvider و MyEnrollmentsProvider إذا أضفت زر التسجيل الداخلي
 import '../../providers/auth_provider.dart';
 import '../../providers/my_enrollments_provider.dart';


class PublicTrainingCourseDetailsScreen extends StatefulWidget {
  final int courseId;

  const PublicTrainingCourseDetailsScreen({super.key, required this.courseId});

  @override
  State<PublicTrainingCourseDetailsScreen> createState() => _PublicTrainingCourseDetailsScreenState();
}

class _PublicTrainingCourseDetailsScreenState extends State<PublicTrainingCourseDetailsScreen> {
  // لا حاجة لتهيئة Provider هنا، سيتم استخدامه في FutureBuilder

  @override
  Widget build(BuildContext context) {
    // يمكن الوصول إلى Provider للاستدعاء فقط (listen: false) إذا لزم الأمر
    //final courseProvider = Provider.of<PublicTrainingCourseProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الدورة'), // يمكن تغيير العنوان لاحقاً بعد جلب البيانات
      ),
      // استخدام FutureBuilder لجلب بيانات الدورة عند بناء الشاشة
      body: FutureBuilder<TrainingCourse?>(
        // استخدام تابع جلب الدورة الفردي من Provider
        // نستخدم listen: false لأننا داخل FutureBuilder ونريد فقط النتيجة الأولية المستقبلية
        future: Provider.of<PublicTrainingCourseProvider>(context, listen: false).fetchTrainingCourse(widget.courseId),
        builder: (context, snapshot) {
          // حالات التحميل والخطأ والبيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // عرض خطأ من الـ Provider إذا كان متاحاً، أو خطأ snapshot
            // هنا قد تحتاج listen: true لقراءة error من provider، أو الأفضل جلب الخطأ من FutureBuilder نفسه
            // أو ببساطة عرض خطأ snapshot.error
            final provider = Provider.of<PublicTrainingCourseProvider>(context, listen: false); // استخدم listen: false هنا لتجنب مشاكل محتملة مع FutureBuilder
            final errorMessage = provider.error ?? snapshot.error?.toString() ?? 'حدث خطأ غير معروف';
            return Center(child: Text('حدث خطأ: $errorMessage'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('لم يتم العثور على الدورة.'));
          } else {
            // عرض تفاصيل الدورة بعد جلبها بنجاح
            final course = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الدورة
                  Text(
                    course.courseName ?? 'عنوان الدورة غير معروف',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // المدرب والموقع (إذا كان متاحاً)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المدرب: ${course.trainersName ?? 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الموقع: ${course.site ?? 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (course.trainersSite != null && course.trainersSite!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.business_outlined, size: 20, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'منصة/جهة التدريب: ${course.trainersSite}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // التواريخ والمستوى والشهادة
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'التواريخ: ${course.startDate != null ? DateFormat('dd/MM/yyyy').format(course.startDate!) : 'غير محدد'} - ${course.endDate != null ? DateFormat('dd/MM/yyyy').format(course.endDate!) : 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bar_chart_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المستوى: ${course.stage ?? 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.card_membership_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'شهادة: ${course.certificate ?? 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // وصف الدورة
                  Text(
                    'الوصف:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.courseDescription ?? 'لا يوجد وصف مفصل لهذه الدورة.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // رابط التسجيل (إذا كان متاحاً)
                  if (course.enrollHyperLink != null && course.enrollHyperLink!.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('التسجيل في الدورة'),
                        onPressed: () async {
                          // فتح الرابط في متصفح خارجي
                          final url = course.enrollHyperLink!;
                          try {
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            } else {
                              // التعامل مع الخطأ إذا تعذر فتح الرابط
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('لا يمكن فتح الرابط: $url')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('حدث خطأ أثناء فتح الرابط: $e')),
                            );
                          }
                        },
                      ),
                    ),

                  // TODO: إضافة زر للتسجيل في الدورة من داخل التطبيق إذا كان مسموحاً (يحتاج مستخدم مصادق عليه وتابع في MyEnrollmentsProvider)
                  if (Provider.of<AuthProvider>(context).isAuthenticated) // تحقق من المصادقة
                    ElevatedButton(
                      onPressed: () {
                         // استدعاء تابع التسجيل في الدورة من MyEnrollmentsProvider
                          Provider.of<MyEnrollmentsProvider>(context, listen: false).enrollInCourse(context, course.courseId!);
                      },
                      child: const Text('التسجيل'),
                    ),


                  const SizedBox(height: 16), // مساحة إضافية في النهاية

                ],
              ),
            );
          }
        },
      ),
    );
  }
}