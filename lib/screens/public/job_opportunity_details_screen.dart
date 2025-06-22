// lib/screens/public_views/public_job_opportunity_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
// ستحتاج مكتبة url_launcher لفتح الرابط إذا كان موجوداً (مثلاً لرابط خارجي للتسجيل إذا كان موجوداً وغير معالج داخلياً)
// import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher_string.dart';

import '../../models/job_opportunity.dart';
import '../../providers/my_applications_provider.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../../services/api_service.dart'; // لاستخدام ApiException
import '../../providers/auth_provider.dart'; // للاستماع لحالة المصادقة وعرض زر التقديم
// TODO: استيراد MyApplicationsProvider لاستدعاء تابع التقديم
// import '../../providers/my_applications_provider.dart';


class PublicJobOpportunityDetailsScreen extends StatefulWidget {
  final int jobId;

  const PublicJobOpportunityDetailsScreen({super.key, required this.jobId});

  @override
  State<PublicJobOpportunityDetailsScreen> createState() => _PublicJobOpportunityDetailsScreenState();
}

class _PublicJobOpportunityDetailsScreenState extends State<PublicJobOpportunityDetailsScreen> {
  // لا حاجة لتهيئة Provider هنا، سيتم استخدامه في FutureBuilder

  @override
  Widget build(BuildContext context) {
    // نستخدم watch هنا للاستماع لحالة المصادقة لتحديد ما إذا كنا سنعرض زر التقديم
    final authProvider = context.watch<AuthProvider>();
    // يمكن الوصول إلى Provider لفرص العمل للاستدعاء فقط (listen: false) إذا لزم الأمر
    // final jobProvider = Provider.of<PublicJobOpportunityProvider>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفرصة'), // يمكن تغيير العنوان لاحقاً بعد جلب البيانات
      ),
      // استخدام FutureBuilder لجلب بيانات الفرصة عند بناء الشاشة
      body: FutureBuilder<JobOpportunity?>(
        // استخدام تابع جلب الفرصة الفردي من Provider
        // نستخدم listen: false لأننا داخل FutureBuilder ونريد فقط النتيجة الأولية المستقبلية
        future: Provider.of<PublicJobOpportunityProvider>(context, listen: false).fetchJobOpportunity(widget.jobId),
        builder: (context, snapshot) {
          // حالات التحميل والخطأ والبيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // عرض خطأ من الـ Provider إذا كان متاحاً، أو خطأ snapshot
            // هنا نستخدم listen: false للحفاظ على الأداء داخل FutureBuilder
            final provider = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
            final errorMessage = provider.error ?? snapshot.error?.toString() ?? 'حدث خطأ غير معروف';
            return Center(child: Text('حدث خطأ: $errorMessage'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('لم يتم العثور على الفرصة.'));
          } else {
            // عرض تفاصيل الفرصة بعد جلبها بنجاح
            final job = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان الوظيفة/التدريب
                  Text(
                    job.jobTitle ?? 'عنوان غير معروف',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // نوع الفرصة (وظيفة/تدريب)
                  Text(
                    'النوع: ${job.type ?? 'غير محدد'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),

                  // تاريخ النشر وتاريخ الانتهاء
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تاريخ النشر: ${job.date != null ? DateFormat('dd/MM/yyyy').format(job.date!) : 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.date_range_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'آخر موعد للتقديم: ${job.endDate != null ? DateFormat('dd/MM/yyyy').format(job.endDate!) : 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // الموقع
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 20, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الموقع: ${job.site ?? 'غير محدد'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),


                  // المؤهلات
                  Text(
                    'المؤهلات المطلوبة:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.qualification ?? 'لا يوجد مؤهلات محددة.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),


                  // المهارات المطلوبة
                  Text(
                    'المهارات المطلوبة:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // TODO: تحليل حقل skills إذا كان نصياً معقداً (JSON أو تنسيق آخر غير بسيط)
                  // حالياً يفترض أنه نص بسيط أو مفصول بفواصل كما في TrainingCourse
                  if (job.skills != null && job.skills!.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: (job.skills!.split(',')) // تقسيم المهارات حسب الفاصلة
                          .map((skill) => Chip(
                        label: Text(skill.trim()), // إزالة المسافات الزائدة
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                      ))
                          .toList(),
                    )
                  else
                    Text('لا توجد مهارات محددة', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),


                  // وصف الوظيفة/التدريب
                  Text(
                    'الوصف التفصيلي:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.jobDescription ?? 'لا يوجد وصف تفصيلي لهذه الفرصة.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // الناشر (الشركة أو المستخدم)
                  if (job.user != null)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 20, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الناشر: ${job.user!.firstName} ${job.user!.lastName}', // أو اسم الشركة إذا كان متاحاً
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),


                  // زر التقديم (يظهر فقط للمستخدمين المصادق عليهم)
                  if (authProvider.isAuthenticated)
                    Center(
                      // TODO: التعامل مع حالة التحميل والخطأ لعملية التقديم بشكل أفضل (ربما Provider منفصل أو حالة تحميل في MyApplicationsProvider)
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('تقديم طلب'),
                        onPressed: () async {
                          // TODO: قد تحتاج لعرض نموذج لإدخال الوصف ومسار السيرة الذاتية إذا كانت مطلوبة
                          final bool? confirmApply = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تأكيد التقديم'),
                              content: const Text('هل أنت متأكد أنك تريد تقديم طلب لهذه الفرصة؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('تقديم'),
                                ),
                              ],
                            ),
                          );

                          if (confirmApply == true && job.jobId != null) {
                            try {
                              // TODO: استدعاء تابع التقديم من MyApplicationsProvider
                              // ستحتاج استيراد MyApplicationsProvider واستخدامه هنا
                              await Provider.of<MyApplicationsProvider>(context, listen: false).applyForJob(context, job.jobId!, description: '', cvPath: ''); // يجب توفير البيانات الفعلية هنا
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تقديم طلبك بنجاح!')),
                              );
                              // TODO: قد تحتاج لإعادة جلب قائمة طلباتي لتحديثها

                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   const SnackBar(content: Text('وظيفة التقديم قيد التطوير.')), // رسالة مؤقتة
                              // );

                            } on ApiException catch (e) {
                              // التعامل مع أخطاء API (مثل أخطاء التحقق أو أن المستخدم قدم بالفعل)
                              String errorMessage = e.message;
                              // إذا كان هناك أخطاء تحقق تفصيلية
                              if (e.errors != null) {
                                errorMessage += '\n' + e.errors!.entries.map((entry) => '${entry.key}: ${entry.value.join(', ')}').join('\n');
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل التقديم: $errorMessage')),
                              );
                              print('API Apply Error: ${e.toString()}');
                            } catch (e) {
                              // التعامل مع الأخطاء العامة الأخرى
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل التقديم: ${e.toString()}')),
                              );
                              print('Unexpected Apply Error: ${e.toString()}');
                            }
                          }
                        },
                      ),
                    ),
                  // TODO: إضافة زر لإلغاء الطلب إذا كان المستخدم قد قدم بالفعل (يحتاج حالة في MyApplicationsProvider)

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