// lib/screens/public_views/PublicJobOpportunitiesScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/public_job_opportunity_provider.dart';
import '../../models/job_opportunity.dart';
import '../widgets/empty_state_widget.dart'; // تأكد من استيراد هذه الويدجت
// استيراد شاشة تفاصيل فرصة العمل الجديدة
import 'job_opportunity_details_screen.dart';


class PublicJobOpportunitiesScreen extends StatefulWidget {
  const PublicJobOpportunitiesScreen({super.key});
  @override
  State<PublicJobOpportunitiesScreen> createState() => _PublicJobOpportunitiesScreenState();
}

class _PublicJobOpportunitiesScreenState extends State<PublicJobOpportunitiesScreen> with AutomaticKeepAliveClientMixin {
  // إضافة ScrollController لدعم التمرير اللانهائي
  final ScrollController _scrollController = ScrollController();


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
      // جلب الصفحة الأولى فقط إذا كانت القائمة فارغة لتجنب إعادة الجلب غير الضرورية عند العودة للشاشة
      if (p.jobs.isEmpty) {
        p.fetchJobOpportunities();
      }
      // TODO: قد تحتاج إلى إعادة جلب القائمة إذا مر وقت طويل منذ آخر جلب أو بناءً على حدث معين
    });

    // إضافة مستمع للتمرير اللانهائي
    _scrollController.addListener(() {
      // تحقق مما إذا كان المستخدم قد وصل إلى نهاية القائمة تقريباً (مثلاً، آخر 200 بكسل)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // تحقق مما إذا كان هناك المزيد من الصفحات للجلب وأننا لا نجلب حالياً
        final provider = Provider.of<PublicJobOpportunityProvider>(context, listen: false);
        if (provider.hasMorePages && !provider.isFetchingMore) {
          provider.fetchMoreJobOpportunities();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // تنظيف الـ controller
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<PublicJobOpportunityProvider>(); // استخدم watch للاستماع للتغييرات

    // عرض مؤشر تحميل إذا كانت القائمة فارغة ويتم تحميلها لأول مرة
    if (provider.isLoading && provider.jobs.isEmpty) {
      return _buildShimmerLoading();
    }

    // عرض رسالة خطأ إذا حدث خطأ والقائمة فارغة
    if (provider.error != null && provider.jobs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.wifi_off_rounded,
        title: 'أُوôs! حدث خطأ',
        message: 'تعذر تحميل البيانات. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
        onRefresh: () => provider.fetchJobOpportunities(),
      );
    }

    // عرض رسالة إذا كانت القائمة فارغة بعد التحميل
    if (provider.jobs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'لا توجد فرص حالياً',
        message: 'يبدو أنه لا توجد وظائف متاحة في الوقت الحالي. تحقق مرة أخرى لاحقاً!',
      );
    }

    // عرض القائمة مع إمكانية السحب للتحديث
    return RefreshIndicator(
      onRefresh: () => provider.fetchJobOpportunities(), // عند السحب للأسفل، قم بجلب الصفحة الأولى مجدداً
      child: ListView.builder(
        controller: _scrollController, // ربط الـ controller بالتمرير
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: provider.jobs.length + (provider.isFetchingMore ? 1 : 0), // +1 لعرض مؤشر التحميل في نهاية القائمة
        itemBuilder: (context, index) {
          // إذا وصلنا إلى العنصر الأخير وكان هناك جلب للمزيد، اعرض مؤشر التحميل
          if (index == provider.jobs.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // عرض بطاقة الفرصة
          final job = provider.jobs[index];
          return JobCard(job: job) // <-- نمرر بيانات الوظيفة إلى البطاقة
          // إضافة تأثيرات الحركة عند ظهور العنصر
              .animate(delay: (120 * (index % 10)).ms)
              .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
              .slideX(begin: -0.2, duration: 800.ms, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  // بناء شاشة تحميل وهمية (Shimmer)
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: 6, // عدد العناصر الوهمية
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 140, // ارتفاع تقريبي لبطاقة الفرصة
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ويدجت البطاقة المخصصة للوظائف ---
class JobCard extends StatefulWidget {
  final JobOpportunity job; // <-- هذا البارامتر مطلوب
  const JobCard({Key? key, required this.job}) : super(key: key); // <-- تم تعريفه هنا
  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        transform: _isHovered ? (Matrix4.identity()..translate(0.0, -8.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? theme.primaryColor : Colors.grey.shade200,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? theme.primaryColor.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            // !!! التعديل هنا !!!
            onTap: () {
              // الانتقال إلى شاشة تفاصيل الفرصة عند النقر
              // نمرر jobId للشاشة الجديدة لتجلب التفاصيل بنفسها
              if (widget.job.jobId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicJobOpportunityDetailsScreen(jobId: widget.job.jobId!),
                  ),
                );
              } else {
                // التعامل مع حالة عدم وجود معرف للوظيفة (غير متوقع)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يمكن عرض تفاصيل هذه الفرصة')),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // أيقونة الوظيفة/التدريب
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(widget.job.type == 'تدريب' ? Icons.model_training_outlined : Icons.work_outline, color: theme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // عنوان الوظيفة واسم الشركة/الناشر
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.jobTitle ?? 'عنوان غير معروف',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // يمكن أن يكون الناشر هو المستخدم أو قد تحتاج لعرض اسم الشركة المرتبطة بالمستخدم
                          // بناءً على الموديل الحالي، هو يعرض اسم المستخدم الناشر (PartialUser)
                          widget.job.user?.firstName != null ? '${widget.job.user!.firstName} ${widget.job.user!.lastName}' : 'شركة غير معروفة',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  // أيقونة الانتقال
                  Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}