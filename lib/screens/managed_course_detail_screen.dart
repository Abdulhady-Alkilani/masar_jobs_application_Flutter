import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_training_course_provider.dart'; // لجلب وتحديث وحذف الدورة
import '../providers/course_enrollees_provider.dart'; // لجلب المسجلين
import '../models/training_course.dart';
import '../models/enrollee.dart'; // لعرض المسجلين
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشات TODO المطلوبة
import 'edit_course_screen.dart'; // <--- شاشة تعديل الدورة
import 'enrollee_detail_screen.dart'; // <--- شاشة تفاصيل المسجل (للانتقال إليها)


class ManagedCourseDetailScreen extends StatefulWidget {
  final int courseId; // معرف الدورة

  const ManagedCourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _ManagedCourseDetailScreenState createState() => _ManagedCourseDetailScreenState();
}

class _ManagedCourseDetailScreenState extends State<ManagedCourseDetailScreen> {
  TrainingCourse? _course; // لتخزين بيانات الدورة الفردية
  String? _courseError; // لتخزين خطأ جلب الدورة
  bool _isLoadingInitialData = false; // حالة تحميل خاصة بالشاشة لجلب البيانات الأولية
  bool _isDeleting = false; // حالة تحميل خاصة بعملية الحذف

  @override
  void initState() {
    super.initState();
    _fetchCourseAndEnrollees(); // جلب تفاصيل الدورة والمسجلين بها عند التهيئة
  }

  // تابع لجلب تفاصيل الدورة والمسجلين بها
  Future<void> _fetchCourseAndEnrollees() async {
    setState(() { _isLoadingInitialData = true;
    //  _initialDataError = null;
    }); // استخدام حالة تحميل أولية

    final courseProvider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);
    final enrolleesProvider = Provider.of<CourseEnrolleesProvider>(context, listen: false);

    try {
      // حاول جلب الدورة من القائمة المحلية أولاً
      final initialCourseFromList = courseProvider.managedCourses.firstWhereOrNull((c) => c.courseId == widget.courseId);

      if (initialCourseFromList != null) {
        // إذا وجدت في القائمة، استخدم بياناتها
        setState(() { _course = initialCourseFromList; _courseError = null; });
      } else {
        // إذا لم توجد في القائمة المحلية، يجب جلبها من API
        // TODO: إضافة تابع fetchSingleManagedCourse(BuildContext context, int courseId) إلى ManagedTrainingCourseProvider و ApiService
        // هذا التابع في AdminCourseProvider اسمه fetchSingleCourse. يجب إضافة واحد مشابه هنا.
        // For now, we will indicate error if not found in the loaded list.
        setState(() {
          _course = null;
          _courseError = 'الدورة بمعرف ${widget.courseId} غير موجودة في القائمة المحملة حالياً.'; // <-- رسالة تشير إلى عدم وجودها في القائمة
        });

        // TODO: الأفضل هو جلبها من API هنا إذا لم توجد في القائمة
        /*
         try {
             final fetchedCourseFromApi = await courseProvider.fetchSingleManagedCourse(context, widget.courseId);
             setState(() { _course = fetchedCourseFromApi; _courseError = null; });
         } on ApiException catch (e) {
             setState(() { _course = null; _courseError = e.message; });
         } catch (e) {
             setState(() { _course = null; _courseError = 'فشل جلب الدورة: ${e.toString()}'; });
         }
         */
      }


      // إذا تم جلب الدورة بنجاح (سواء من القائمة أو بتابع مخصص لاحقاً)، جلب المسجلين بها
      if (_course != null && _courseError == null) { // تأكد من أن الدورة موجودة ولا يوجد خطأ أساسي
        await enrolleesProvider.fetchEnrollees(context, widget.courseId);
      }


    } on ApiException catch (e) {
      // يمكن معالجة أخطاء CourseEnrolleesProvider بشكل منفصل لاحقاً
      // _courseError = e.message; // لا نغير خطأ الدورة إذا كان الخطأ في المسجلين
      print('API Exception during fetchCourseAndEnrollees: ${e.message}');
    } catch (e) {
      // _courseError = 'فشل جلب المسجلين: ${e.toString()}'; // لا نغير خطأ الدورة
      print('Unexpected error during fetchCourseAndEnrollees: ${e.toString()}');
    } finally {
      setState(() { _isLoadingInitialData = false; });
    }
  }

  // تابع لحذف الدورة
  Future<void> _deleteCourse() async {
    // لا يمكن الحذف بدون معرف أو إذا كان يتم التحميل أو الحذف بالفعل
    if (_course?.courseId == null || _isLoadingInitialData || _isDeleting) return;


    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف الدورة "${_course!.courseName ?? 'بدون عنوان'}"؟ سيتم حذف جميع تسجيلات الطلاب المرتبطة بها أيضاً.'), // إضافة تحذير
          actions: <Widget>[
            TextButton(child: const Text('إلغاء'), onPressed: () { Navigator.of(dialogContext).pop(false); }),
            TextButton(child: const Text('حذف', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(dialogContext).pop(true); }),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      setState(() { _isDeleting = true; }); // بداية التحميل للحذف

      final provider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);
      try {
        // استدعاء تابع الحذف في Provider
        await provider.deleteCourse(context, _course!.courseId!);

        // بعد النجاح، العودة إلى شاشة قائمة الدورات المنشورة
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الدورة بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الدورة: ${e.toString()}')),
        );
      } finally {
        setState(() { _isDeleting = false; }); // انتهاء التحميل للحذف
      }
    }
  }

  // تابع للانتقال إلى شاشة تعديل الدورة
  void _editCourse() {
    // لا يمكن التعديل بدون كائن الدورة أو إذا كنا في حالة تحميل
    if (_course == null || _isLoadingInitialData || _isDeleting) return;

    print('Edit Course Tapped for course ID ${widget.courseId}');
    Navigator.push(
      context,
      MaterialPageRoute(
        // نمرر معرف الدورة لشاشة التعديل لتقوم هي بجلب تفاصيل الدورة
        builder: (context) => EditCourseScreen(courseId: widget.courseId),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // هنا نستمع للـ CourseEnrolleesProvider فقط لأن حالته (isLoading, error, enrollees) تتغير بشكل منفصل بعد جلب الدورة
    final enrolleesProvider = Provider.of<CourseEnrolleesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.courseName ?? 'تفاصيل الدورة'),
        actions: [
          // عرض الأزرار فقط إذا تم جلب الدورة بنجاح ولم نكن في حالة جلب البيانات الأولية أو الحذف
          if (_course != null && !_isLoadingInitialData && !_isDeleting) ...[
            // زر التعديل
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: enrolleesProvider.isLoading ? null : _editCourse, // تعطيل الزر أثناء تحميل المسجلين واستدعاء تابع الانتقال
            ),
            // زر الحذف
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoadingInitialData || _isDeleting || enrolleesProvider.isLoading ? null : _deleteCourse, // تعطيل الزر أثناء أي تحميل
            ),
          ],
        ],
      ),
      // عرض مؤشر تحميل أثناء جلب البيانات الأولية أو أثناء الحذف
      body: _isLoadingInitialData || _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : _courseError != null // خطأ جلب البيانات الأولية
          ? Center(child: Text('Error: ${_courseError!}'))
          : _course == null // بيانات الدورة غير موجودة بعد التحميل
          ? const Center(child: Text('الدورة غير موجودة.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الدورة
            Text(
              _course!.courseName ?? 'بدون عنوان',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // TODO: عرض معلومات الناشر (UserID) هنا إذا كانت محملة في كائن الدورة (_course!.userId)
            if (_course!.userId != null) Text('الناشر UserID: ${_course!.userId}', style: const TextStyle(fontSize: 16)),

            Text(
              'المدرب: ${_course!.trainersName ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'المكان: ${_course!.site ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'جهة التدريب: ${_course!.trainersSite ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'المستوى: ${_course!.stage ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'الشهادة: ${_course!.certificate ?? 'غير محدد'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'تاريخ البدء: ${_course!.startDate?.toString().split(' ')[0] ?? 'غير معروف'}',
              style: const TextStyle(fontSize: 14),
            ),
            if (_course!.endDate != null)
              Text(
                'تاريخ الانتهاء: ${_course!.endDate!.toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 14),
              ),
            if (_course!.enrollHyperLink != null)
              Text(
                'رابط التسجيل: ${_course!.enrollHyperLink!}',
                style: const TextStyle(fontSize: 14, color: Colors.blue), // TODO: جعله clickable
              ),
            const SizedBox(height: 16),
            const Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _course!.courseDescription ?? 'لا يوجد وصف متاح.',
              style: const TextStyle(fontSize: 16),
            ),

            const Divider(height: 32),

            const Text('المسجلون:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            enrolleesProvider.isLoading // حالة تحميل المسجلين
                ? const Center(child: CircularProgressIndicator())
                : enrolleesProvider.error != null // خطأ في جلب المسجلين
                ? Center(child: Text('Error loading enrollees: ${enrolleesProvider.error}'))
                : enrolleesProvider.enrollees.isEmpty // لا يوجد مسجلون
                ? const Center(child: Text('لا يوجد مسجلون حالياً في هذه الدورة.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enrolleesProvider.enrollees.length,
              itemBuilder: (context, index) {
                final enrollee = enrolleesProvider.enrollees[index];
                // تأكد أن المسجل لديه كائن User محمل
                final enrolleeUser = enrollee.user;
                if (enrollee.enrollmentId == null || enrolleeUser == null) return const SizedBox.shrink();


                return ListTile(
                  title: Text('${enrolleeUser.firstName ?? ''} ${enrolleeUser.lastName ?? ''} (${enrolleeUser.username ?? ''})'), // اسم المستخدم واسم المستخدم
                  subtitle: Text('حالة التسجيل: ${enrollee.status ?? 'غير محدد'}'),
                  trailing: Text(enrollee.date?.toString().split(' ')[0] ?? ''),
                  onTap: () {
                    // الانتقال إلى شاشة تفاصيل المسجل
                    print('Enrollee tapped: ${enrolleeUser.username}');
                    // الانتقال لشاشة تفاصيل المسجل، مع تمرير كائن المسجل الكامل
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EnrolleeDetailScreen(enrollee: enrollee) // <--- الانتقال لشاشة تفاصيل المسجل
                      ),
                    );
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