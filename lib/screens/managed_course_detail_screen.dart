import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/managed_training_course_provider.dart'; // لجلب وتحديث الدورة
import '../providers/course_enrollees_provider.dart'; // لجلب المسجلين
import '../models/training_course.dart';
import '../models/enrollee.dart'; // لعرض المسجلين

class ManagedCourseDetailScreen extends StatefulWidget {
  final int courseId;

  const ManagedCourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _ManagedCourseDetailScreenState createState() => _ManagedCourseDetailScreenState();
}

class _ManagedCourseDetailScreenState extends State<ManagedCourseDetailScreen> {
  TrainingCourse? _course;
  String? _courseError;

  @override
  void initState() {
    super.initState();
    _fetchCourseAndEnrollees();
  }

  // تابع لجلب تفاصيل الدورة والمسجلين بها
  Future<void> _fetchCourseAndEnrollees() async {
    final courseProvider = Provider.of<ManagedTrainingCourseProvider>(context, listen: false);
    final enrolleesProvider = Provider.of<CourseEnrolleesProvider>(context, listen: false);

    try {
      // Fetch the specific course details (can use the general public provider's fetch method or add one to managed provider)
      // Let's use the public one for simplicity if it exists and fetches full details
      // OR fetch from the list in ManagedTrainingCourseProvider
      final fetchedCourse = courseProvider.managedCourses.firstWhereOrNull((c) => c.courseId == widget.courseId);

      if (fetchedCourse != null) {
        setState(() {
          _course = fetchedCourse;
          _courseError = null;
        });
      } else {
        // Fallback: If not found in the loaded list, try to fetch individually
        // NOTE: ApiService doesn't have a *public* fetchCourse by ID, only *managed*.
        // So you MUST use the ManagedTrainingCourseProvider's method here.
        // We need a fetchSingleManagedCourse method in ManagedTrainingCourseProvider.
        // For now, let's assume the list is comprehensive or fallback logic exists.
        // Let's call fetchManagedCourses(context) to ensure list is populated and then get from it
        await courseProvider.fetchManagedCourses(context); // Ensure list is loaded/updated
        final refetchedCourse = courseProvider.managedCourses.firstWhereOrNull((c) => c.courseId == widget.courseId);
        if (refetchedCourse != null) {
          setState(() { _course = refetchedCourse; _courseError = null; });
        } else {
          setState(() { _course = null; _courseError = 'الدورة غير موجودة.'; });
        }
      }


      // إذا تم جلب الدورة بنجاح، جلب المسجلين بها
      if (_course != null) {
        await enrolleesProvider.fetchEnrollees(context, widget.courseId);
      }

    } catch (e) {
      setState(() {
        _course = null;
        _courseError = 'فشل جلب بيانات الدورة أو المسجلين: ${e.toString()}';
      });
    }
  }


  // TODO: تابع لحذف الدورة (يستدعي managedTrainingCourseProvider.deleteCourse)
  // TODO: تابع لتعديل الدورة (ينتقل لشاشة تعديل)

  @override
  Widget build(BuildContext context) {
    final enrolleesProvider = Provider.of<CourseEnrolleesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.courseName ?? 'تفاصيل الدورة'),
        actions: [
          if (_course != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: الانتقال إلى شاشة تعديل الدورة (EditCourseScreen) أو فتح نموذج
                print('Edit Course Tapped for course ID ${widget.courseId}');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => EditCourseScreen(courseId: widget.courseId)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('وظيفة تعديل الدورة لم تنفذ.')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: تابع لحذف الدورة (ManagedTrainingCourseProvider.deleteCourse) مع تأكيد
                print('Delete Course Tapped for course ID ${widget.courseId}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('وظيفة حذف الدورة لم تنفذ.')),
                );
              },
            ),
          ],
        ],
      ),
      body: _courseError != null
          ? Center(child: Text('Error: $_courseError'))
          : _course == null
          ? const Center(child: CircularProgressIndicator()) // مؤشر جلب الدورة
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض تفاصيل الدورة
            Text(_course!.courseName ?? 'بدون عنوان', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            // ... باقي تفاصيل الدورة ...
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
                return ListTile(
                  title: Text('${enrollee.user?.firstName ?? ''} ${enrollee.user?.lastName ?? ''}'),
                  subtitle: Text('حالة التسجيل: ${enrollee.status ?? 'غير محدد'}'),
                  trailing: Text(enrollee.date?.toString().split(' ')[0] ?? ''),
                  onTap: () {
                    // TODO: الانتقال إلى شاشة تفاصيل المسجل (EnrolleeDetailScreen)
                    print('Enrollee tapped: ${enrollee.user?.username}');
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => EnrolleeDetailScreen(enrollee: enrollee)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('وظيفة عرض تفاصيل المسجل لم تنفذ.')),
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

// TODO: أنشئ شاشة EditCourseScreen لتعديل بيانات الدورة (ستحتاج ManagedTrainingCourseProvider.updateCourse)
// TODO: أنشئ شاشة EnrolleeDetailScreen لعرض تفاصيل المسجل (بياناته، ملفه الشخصي، خيارات لتغيير حالة تسجيله)