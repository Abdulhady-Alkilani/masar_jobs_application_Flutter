import 'dart:convert';
import 'dart:io'; // Added for File
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:shared_preferences/shared_preferences.dart'; // <--- 1. إضافة استيراد SharedPreferences


// استيراد جميع الموديلات التي أنشأتها
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/profile.dart';
import '../models/skill.dart';
import '../models/article.dart';
import '../models/job_opportunity.dart';
import '../models/training_course.dart';
import '../models/company.dart';
import '../models/group.dart';
import '../models/job_application.dart';
import '../models/enrollment.dart';
import '../models/recommendation_response.dart';
import '../models/paginated_response.dart';
import '../models/applicant.dart';
import '../models/enrollee.dart';
import '../models/group.dart'; // تأكد من مسار Group الصحيح

// فئة مخصصة لأخطاء API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.statusCode, this.message, {this.errors});

  @override
  String toString() {
    return 'ApiException: Status Code $statusCode - $message\nErrors: $errors';
  }
}

class ApiService {
  // عنوان URL الأساسي لواجهة برمجة التطبيقات
  static const String _baseUrl = 'https://powderblue-woodpecker-887296.hostingersite.com/api/v1';

  static const String baseUrlStorage = 'https://powderblue-woodpecker-887296.hostingersite.com/storage/';

  // مفتاح تخزين التوكن في SharedPreferences
  static const String _authTokenKey = 'authToken'; // <--- تعريف مفتاح التوكن

  // ترويسات الطلب الافتراضية
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // طريقة مساعدة لإجراء طلبات GET
  Future<http.Response> _get(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{};
    headers.addAll(_defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      print('GET: $url');
      print('Headers: $headers');
    }
    return await http.get(url, headers: headers);
  }

  // طريقة مساعدة لإجراء طلبات POST
  Future<http.Response> _post(String endpoint, dynamic body, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{};
    headers.addAll(_defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      print('POST: $url');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
    }
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  // طريقة مساعدة لإجراء طلبات PUT
  Future<http.Response> _put(String endpoint, dynamic body, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{};
    headers.addAll(_defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      print('PUT: $url');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
    }
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  // طريقة مساعدة لإجراء طلبات DELETE
  Future<http.Response> _delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{};
    headers.addAll(_defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      print('DELETE: $url');
      print('Headers: $headers');
    }
    return await http.delete(url, headers: headers);
  }

  // في ملف api_service.dart

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('--- API Response ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('--------------------');
    }

    // التحقق أولاً إذا كانت الاستجابة HTML
    if (response.body.trim().startsWith('<!DOCTYPE html>')) {
      print('API Error: Received HTML page instead of JSON. Check hosting bot protection.');
      throw ApiException(response.statusCode, 'خطأ في السيرفر، تم استقبال صفحة ويب بدلاً من بيانات.');
    }

    // الآن نحاول فك ترميز JSON
    try {
      final decodedBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedBody;
      } else {
        throw ApiException(
          response.statusCode,
          decodedBody['message'] ?? 'حدث خطأ غير معروف',
          errors: decodedBody['errors'] as Map<String, dynamic>?,
        );
      }
    } on FormatException catch (e) {
      print('API Error: Failed to decode JSON. Error: $e');
      throw ApiException(response.statusCode, 'السيرفر أعاد استجابة غير متوقعة. لا يمكن قراءة البيانات.');
    }
  }

  // --- 2. SharedPreferences Methods for Token Management ---

  /// حفظ التوكن في SharedPreferences
  Future<void> saveAuthToken(String token) async { // <--- تابع حفظ التوكن
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    if (kDebugMode) {
      print('Auth token saved: $token');
    }
  }

  /// جلب التوكن من SharedPreferences
  Future<String?> getAuthToken() async { // <--- تابع جلب التوكن
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    if (kDebugMode) {
      print('Auth token retrieved: $token');
    }
    return token;
  }

  /// إزالة التوكن من SharedPreferences (عند تسجيل الخروج مثلاً)
  Future<void> removeAuthToken() async { // <--- تابع إزالة التوكن
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    if (kDebugMode) {
      print('Auth token removed');
    }
  }

  // --- 1. Authentication Endpoints ---

  /// تسجيل مستخدم جديد
  Future<AuthResponse> registerUser(String firstName, String lastName, String username, String email, String password, String passwordConfirmation, String phone, String type) async {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'phone': phone,
      'type': type,
    };
    final response = await _post('/register', body);
    final authResponse = AuthResponse.fromJson(_handleResponse(response));
    if (authResponse.accessToken != null) {
      await saveAuthToken(authResponse.accessToken!); // <--- حفظ التوكن عند التسجيل
    }
    return authResponse;
  }

  /// تسجيل دخول المستخدم والحصول على توكن
  Future<AuthResponse> loginUser(String email, String password) async {
    final body = {'email': email, 'password': password};
    final response = await _post('/login', body);
    final authResponse = AuthResponse.fromJson(_handleResponse(response));
    if (authResponse.accessToken != null) {
      await saveAuthToken(authResponse.accessToken!); // <--- حفظ التوكن عند تسجيل الدخول
    }
    return authResponse;
  }

  /// تسجيل خروج المستخدم وإبطال التوكن
  Future<void> logoutUser(String token) async {
    final response = await _post('/logout', {}, token: token);
    _handleResponse(response); // Expected 200 OK
    await removeAuthToken(); // <--- إزالة التوكن محليًا بعد تسجيل الخروج من API
  }


  // --- 2. Public Endpoints (Already implemented, access token parameter is optional) ---

  /// جلب قائمة المقالات
  Future<PaginatedResponse<Article>> fetchArticles({int page = 1}) async {
    final response = await _get('/articles?page=$page');
    return PaginatedResponse<Article>.fromJson(_handleResponse(response), (json) => Article.fromJson(json));
  }

  /// جلب مجموعة محددة (Public)
  Future<Group> fetchGroup(int groupId) async {
    final response = await _get('/groups/$groupId'); // مسار عام لا يحتاج توكن
    return Group.fromJson(_handleResponse(response));
  }
  /// جلب قائمة المجموعات (Public)
  /// يُستخدم لجلب قائمة بجميع المجموعات المتاحة (مثل روابط تيليجرام).
  /// هذا المسار لا يتطلب مصادقة.
  Future<List<Group>> fetchGroups() async {
    // استخدام التابع المساعد _get لإرسال طلب GET إلى مسار '/groups'
    final response = await _get('/groups');

    // معالجة الاستجابة باستخدام التابع المساعد _handleResponse
    // هذا التابع سيتحقق من كود الحالة، يرمي استثناءات عند الخطأ، ويفك ترميز JSON عند النجاح.
    final List<dynamic> data = _handleResponse(response);

    // تحويل قائمة الـ dynamic (التي تمثل كائنات JSON للمجموعات) إلى قائمة من موديلات Group
    // نستخدم map لتمرير كل عنصر في القائمة إلى دالة Group.fromJson
    // ثم نستخدم toList() لتحويل الناتج (Iterable) إلى List.
    return data.map((json) => Group.fromJson(json)).toList();
  }

  /// جلب مقال محدد
  Future<Article> fetchArticle(int articleId) async {
    final response = await _get('/articles/$articleId');
    return Article.fromJson(_handleResponse(response));
  }

  /// جلب قائمة فرص العمل/التدريب
  Future<PaginatedResponse<JobOpportunity>> fetchJobOpportunities({int page = 1}) async {
    final response = await _get('/jobs?page=$page');
    return PaginatedResponse<JobOpportunity>.fromJson(_handleResponse(response), (json) => JobOpportunity.fromJson(json));
  }

  /// جلب فرصة عمل/تدريب محددة
  Future<JobOpportunity> fetchJobOpportunity(int jobId) async {
    final response = await _get('/jobs/$jobId');
    return JobOpportunity.fromJson(_handleResponse(response));
  }

  /// جلب قائمة الدورات التدريبية
  Future<PaginatedResponse<TrainingCourse>> fetchTrainingCourses({int page = 1}) async {
    final response = await _get('/courses?page=$page');
    return PaginatedResponse<TrainingCourse>.fromJson(_handleResponse(response), (json) => TrainingCourse.fromJson(json));
  }

  /// جلب دورة تدريبية محددة
  Future<TrainingCourse> fetchTrainingCourse(int courseId) async {
    final response = await _get('/courses/$courseId');
    return TrainingCourse.fromJson(_handleResponse(response));
  }

  /// جلب قائمة الشركات
  Future<PaginatedResponse<Company>> fetchCompanies({int page = 1}) async {
    final response = await _get('/companies?page=$page');
    return PaginatedResponse<Company>.fromJson(_handleResponse(response), (json) => Company.fromJson(json));
  }

  /// جلب شركة محددة
  Future<Company> fetchCompany(int companyId) async {
    final response = await _get('/companies/$companyId');
    return Company.fromJson(_handleResponse(response));
  }

  /// جلب قائمة المهارات (مع إمكانية البحث)
  Future<List<Skill>> fetchSkills({String? searchTerm}) async {
    final endpoint = searchTerm != null ? '/skills?search=$searchTerm' : '/skills';
    final response = await _get(endpoint);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => Skill.fromJson(json)).toList();
  }

  // --- 3. Authenticated User Endpoints ---

  /// جلب بيانات المستخدم الحالي
  /// يرسل طلب GET إلى /api/v1/user.
  /// يتطلب توكن المستخدم للمصادقة.
  /// يتم استخدامه في AuthProvider عند checkAuthStatus وبعد عمليات Login/Register لضمان تحديث بيانات المستخدم.
  Future<User> fetchCurrentUser(String token) async {
    // استخدام التابع المساعد _get لإرسال طلب GET إلى مسار '/user' مع إرفاق التوكن
    final response = await _get('/user', token: token);

    // معالجة الاستجابة باستخدام التابع المساعد _handleResponse
    // هذا التابع سيتحقق من كود الحالة، يرمي استثناءات عند الخطأ (مثل 401), ويفك ترميز JSON عند النجاح.
    final dynamic decodedData = _handleResponse(response);

    // تحويل البيانات المفككة (والتي يجب أن تكون Map<String, dynamic> لكائن المستخدم) إلى موديل User
    // _handleResponse يرمي استثناء إذا لم يكن الناتج Map في حالة النجاح (200 OK)
    return User.fromJson(decodedData as Map<String, dynamic>);
  }

  /// جلب مستخدم محدد بواسطة ID (عام)
  Future<User> getUserById(int userId) async {
    final response = await _get('/users/$userId');
    return User.fromJson(_handleResponse(response));
  }

  // ... (باقي توابع ApiService) ...

  /// جلب ملف المستخدم الشخصي
  Future<Profile> fetchUserProfile(String token) async {
    final response = await _get('/profile', token: token);
    return Profile.fromJson(_handleResponse(response));
  }

  /// تحديث ملف المستخدم الشخصي
  Future<Profile> updateUserProfile(String token, Map<String, dynamic> profileData) async {
    final response = await _put('/profile', profileData, token: token);
    return Profile.fromJson(_handleResponse(response));
  }

  /// تحديث مهارات المستخدم
  Future<User>  syncUserSkills(String token, dynamic skillIds) async {
    final body = {'skills': skillIds};
    final response = await _post('/profile/skills', body, token: token);
    return User.fromJson(_handleResponse(response));
  }

  /// جلب طلبات التوظيف الخاصة بالمستخدم الحالي
  Future<List<JobApplication>> fetchMyApplications(String token) async {
    final response = await _get('/my-applications', token: token);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => JobApplication.fromJson(json)).toList();
  }

  /// تقديم طلب لوظيفة
  Future<JobApplication> applyForJob(String token, int jobId, {String? description, String? cvPath}) async {
    final body = {'Description': description, 'CV': cvPath};
    // تأكد من أن backend يقبل jobId في URL وليس في body
    final response = await _post('/jobs/$jobId/apply', body, token: token);
    return JobApplication.fromJson(_handleResponse(response));
  }

  /// حذف طلب توظيف
  Future<void> deleteJobApplication(String token, int applicationId) async {
    final response = await _delete('/my-applications/$applicationId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب تسجيلات الدورات الخاصة بالمستخدم الحالي
  Future<List<Enrollment>> fetchMyEnrollments(String token) async {
    final response = await _get('/my-enrollments', token: token);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => Enrollment.fromJson(json)).toList();
  }

  /// التسجيل في دورة تدريبية
  Future<Enrollment> enrollInCourse(String token, int courseId) async {
    // تأكد أن backend يقبل courseId في URL وليس في body
    final response = await _post('/courses/$courseId/enroll', {}, token: token); // Body is empty
    return Enrollment.fromJson(_handleResponse(response));
  }

  /// حذف تسجيل في دورة تدريبية
  Future<void> deleteEnrollment(String token, int enrollmentId) async {
    final response = await _delete('/my-enrollments/$enrollmentId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب التوصيات للمستخدم الحالي
  Future<RecommendationResponse> fetchRecommendations(String token) async {
    final response = await _get('/recommendations', token: token);
    return RecommendationResponse.fromJson(_handleResponse(response));
  }

  // --- 4. Company Manager Endpoints ---

  /// جلب بيانات الشركة التي يديرها المستخدم
  Future<Company> fetchManagedCompany(String token) async {
    final response = await _get('/company-manager/company-request', token: token);
    return Company.fromJson(_handleResponse(response));
  }

  /// إنشاء شركة جديدة بواسطة المدير (إذا كان هذا السيناريو مسموحاً)
  /// ملاحظة: بناءً على API doc، هذا المسار غير محدد بشكل صريح لمدير الشركة.
  /// قد يكون هذا المسار POST /company-manager/company إذا كان المتحكم يسمح به،
  /// أو قد لا يكون متاحاً ويجب أن يتم إنشاء الشركة فقط عبر طلب يوافق عليه الأدمن.
  /// هذا التابع يفترض أن مساراً من هذا القبيل موجود. تحقق من backend الخاص بك.
  /// هذا مجرد هيكل بناءً على الاسم المطلوب.
  Future<Company> createManagedCompany(String token, Map<String, dynamic> companyData) async {
    // يفترض أن المسار هو POST /company-manager/company
    final response = await _post('/company-manager/company-request', companyData, token: token);
    // يجب أن يعيد المتحكم بيانات الشركة المنشأة في حالة النجاح (201 Created)
    return Company.fromJson(_handleResponse(response));
  }

  /// تحديث حالة متقدم لوظيفة (بواسطة المدير)
  /// ملاحظة: بناءً على API doc، هذا المسار غير محدد بشكل صريح.
  /// هذا التابع يفترض أن هناك مساراً مثل PUT /company-manager/applications/{application_id}/status
  /// أو أن التحديث يتم عبر PUT على JobApplication نفسها.
  /// هذا مجرد هيكل بناءً على الاسم المطلوب. تحقق من backend الخاص بك.
  /// 'newStatus' يجب أن تطابق القيم المتوقعة في backend (مثل 'Reviewed', 'Accepted', 'Rejected').
  Future<JobApplication> updateApplicantStatus(String token, int applicationId, String newStatus) async {
    // يفترض أن المسار هو PUT /company-manager/applications/{application_id}/status
    // أو PUT /company-manager/applications/{application_id} مع body {'Status': newStatus}
    final body = {'Status': newStatus};
    final response = await _put('/company-manager/applications/$applicationId', body, token: token); // استخدام PUT على المورد نفسه
    // يجب أن يعيد المتحكم بيانات طلب التوظيف المحدث في حالة النجاح (200 OK)
    return JobApplication.fromJson(_handleResponse(response));
  }

  /// تحديث حالة تسجيل في دورة (بواسطة المدير أو الاستشاري)
  /// ملاحظة: بناءً على API doc، هذا المسار غير محدد بشكل صريح.
  /// هذا التابع يفترض أن هناك مساراً مثل PUT /managed-enrollments/{enrollment_id}/status
  /// أو أن التحديث يتم عبر PUT على Enrollment نفسها.
  /// هذا مجرد هيكل بناءً على الاسم المطلوب. تحقق من backend الخاص بك.
  /// 'newStatus' يجب أن تطابق القيم المتوقعة في backend (مثل 'مكتمل', 'قيد التقدم', 'ملغي').
  Future<Enrollment> updateEnrolleeStatus(String token, int enrollmentId, String newStatus, {DateTime? completionDate}) async {
    // يفترض أن المسار هو PUT /managed-enrollments/{enrollment_id} مع body {'Status': newStatus, 'Complet Date': completionDate}
    final body = {'Status': newStatus};
    if (completionDate != null) {
      body['Complet Date'] = completionDate.toIso8601String(); // إرسال التاريخ بصيغة ISO 8601
    }
    final response = await _put('/managed-enrollments/$enrollmentId', body, token: token); // استخدام PUT على المورد نفسه
    // يجب أن يعيد المتحكم بيانات التسجيل المحدث في حالة النجاح (200 OK)
    return Enrollment.fromJson(_handleResponse(response));
  }

  /// تحديث حالة طلب توظيف (بواسطة المدير أو الأدمن)
  /// يرسل طلب PUT إلى المسار المناسب في Backend.
  /// **تحقق من Backend:** ما هو المسار الدقيق وطريقة الطلب (PUT) لتحديث حالة طلب توظيف بمعرفه (applicationId)؟
  /// الأمثلة المحتملة للمسار:
  /// - PUT /applications/{applicationId} (إذا كان مساراً عاماً لإدارة الطلبات بواسطة الأدوار)
  /// - PUT /company-manager/applications/{applicationId} (إذا كان مساراً خاصاً بالمدير)
  /// - PUT /admin/job-applications/{applicationId} (إذا كان مساراً خاصاً بالأدمن)
  ///
  /// هذا التابع يفترض مساراً معيناً وسيتطلب تعديلاً إذا كان المسار الفعلي مختلفاً في Backend.
  ///
  /// 'newStatus' يجب أن تطابق القيم المتوقعة في Backend (مثل 'Reviewed', 'Accepted', 'Rejected').
  /// 'description' و 'cvPath' (اختياريان) إذا كان Backend يسمح بتحديثهما مع الحالة.
  Future<JobApplication> updateJobApplicationStatus(String token, int applicationId, String newStatus, {String? description, String? cvPath}) async {
    // **المسار الافتراضي المستخدم هنا:** PUT /applications/{applicationId}
    // **تحقق من backend للتأكد من المسار الصحيح.**

    final body = <String, dynamic>{'Status': newStatus};
    if (description != null) body['Description'] = description;
    if (cvPath != null) body['CV'] = cvPath;

    final response = await _put('/applications/$applicationId', body, token: token);

    // يجب أن يعيد المتحكم بيانات طلب التوظيف المحدث في حالة النجاح (200 OK)
    return JobApplication.fromJson(_handleResponse(response));
  }


  /// تحديث حالة تسجيل في دورة (بواسطة المدير أو الاستشاري أو الأدمن)
  /// يرسل طلب PUT إلى المسار المناسب في Backend.
  /// **تحقق من Backend:** ما هو المسار الدقيق وطريقة الطلب (PUT) لتحديث حالة تسجيل في دورة بمعرفه (enrollmentId)؟
  /// الأمثلة المحتملة للمسار:
  /// - PUT /enrollments/{enrollmentId} (إذا كان مساراً عاماً لإدارة التسجيلات بواسطة الأدوار)
  /// - PUT /company-manager/enrollments/{enrollmentId} (إذا كان مساراً خاصاً بالمدير)
  /// - PUT /consultant/enrollments/{enrollmentId} (إذا كان مساراً خاصاً بالاستشاري)
  /// - PUT /admin/courses/enrollments/{enrollmentId} (إذا كان مساراً خاصاً بالأدمن)
  ///
  /// هذا التابع يفترض مساراً معيناً وسيتطلب تعديلاً إذا كان المسار الفعلي مختلفاً في Backend.
  ///
  /// 'newStatus' يجب أن تطابق القيم المتوقعة في Backend (مثل 'مكتمل', 'قيد التقدم', 'ملغي').
  /// 'completionDate' (اختياري) إذا كان مطلوباً عند تغيير الحالة إلى 'مكتمل'.
  Future<Enrollment> updateEnrollmentStatus(String token, int enrollmentId, String newStatus, {DateTime? completionDate}) async {
    // **المسار الافتراضي المستخدم هنا:** PUT /enrollments/{enrollmentId}
    // **تحقق من backend للتأكد من المسار الصحيح.**

    final body = <String, dynamic>{'Status': newStatus};
    if (completionDate != null) {
      body['Complet Date'] = completionDate.toIso8601String(); // إرسال التاريخ بصيغة ISO 8601
    }

    final response = await _put('/enrollments/$enrollmentId', body, token: token);

    // يجب أن يعيد المتحكم بيانات التسجيل المحدث في حالة النجاح (200 OK)
    return Enrollment.fromJson(_handleResponse(response));
  }

  /// تحديث بيانات الشركة التي يديرها المستخدم
  Future<Company> updateManagedCompany(String token, Map<String, dynamic> companyData) async {
    final response = await _put('/company-manager/company', companyData, token: token);
    return Company.fromJson(_handleResponse(response));
  }

  /// جلب فرص العمل التي نشرها المدير
  Future<PaginatedResponse<JobOpportunity>> fetchManagedJobs(String token, {int page = 1}) async {
    final response = await _get('/company-manager/jobs?page=$page', token: token);
    return PaginatedResponse<JobOpportunity>.fromJson(_handleResponse(response), (json) => JobOpportunity.fromJson(json));
  }

  /// إنشاء فرصة عمل جديدة بواسطة المدير
  Future<JobOpportunity> createManagedJob(String token, Map<String, dynamic> jobData) async {
    final response = await _post('/company-manager/jobs', jobData, token: token);
    return JobOpportunity.fromJson(_handleResponse(response));
  }

  /// تحديث فرصة عمل بواسطة المدير
  Future<JobOpportunity> updateManagedJob(String token, int jobId, Map<String, dynamic> jobData) async {
    final response = await _put('/company-manager/jobs/$jobId', jobData, token: token);
    return JobOpportunity.fromJson(_handleResponse(response));
  }

  /// حذف فرصة عمل بواسطة المدير
  Future<void> deleteManagedJob(String token, int jobId) async {
    final response = await _delete('/company-manager/jobs/$jobId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب الدورات التدريبية التي نشرها المدير
  Future<PaginatedResponse<TrainingCourse>> fetchManagedCourses(String token, {int page = 1}) async {
    final response = await _get('/company-manager/courses?page=$page', token: token);
    return PaginatedResponse<TrainingCourse>.fromJson(_handleResponse(response), (json) => TrainingCourse.fromJson(json));
  }

  /// إنشاء دورة تدريبية جديدة بواسطة المدير
  Future<TrainingCourse> createManagedCourse(String token, Map<String, dynamic> courseData) async {
    final response = await _post('/company-manager/courses', courseData, token: token);
    return TrainingCourse.fromJson(_handleResponse(response));
  }

  /// تحديث دورة تدريبية بواسطة المدير
  Future<TrainingCourse> updateManagedCourse(String token, int courseId, Map<String, dynamic> courseData) async {
    final response = await _put('/company-manager/courses/$courseId', courseData, token: token);
    return TrainingCourse.fromJson(_handleResponse(response));
  }

  /// حذف دورة تدريبية بواسطة المدير
  Future<void> deleteManagedCourse(String token, int courseId) async {
    final response = await _delete('/company-manager/courses/$courseId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب المتقدمين لوظيفة معينة يديرها المدير
  Future<List<Applicant>> fetchJobApplicants(String token, int jobId) async {
    final response = await _get('/company-manager/jobs/$jobId/applicants', token: token);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => Applicant.fromJson(json)).toList();
  }

  /// جلب المسجلين بدورة معينة يديرها المدير
  Future<List<Enrollee>> fetchCourseEnrollees(String token, int courseId) async {
    final response = await _get('/company-manager/courses/$courseId/enrollees', token: token);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => Enrollee.fromJson(json)).toList();
  }

  // --- 5. Consultant Endpoints ---

  /// جلب المقالات التي نشرها الاستشاري
  /// يرسل طلب GET إلى /consultant/articles
  Future<PaginatedResponse<Article>> fetchManagedArticles(String token, {int page = 1}) async {
    final response = await _get('/consultant/articles?page=$page', token: token);
    // _handleResponse سيعيد dynamic (غالباً Map<String, dynamic> أو List<dynamic> أو غير ذلك)
    final dynamic decodedBody = _handleResponse(response);

    // تحقق صريح مما إذا كانت الاستجابة عبارة عن Map (كما هو متوقع لاستجابة Paginated)
    if (decodedBody is Map<String, dynamic>) {
      // إذا كانت Map، فمن الآمن تمريرها إلى fromJson
      return PaginatedResponse<Article>.fromJson(decodedBody, (json) => Article.fromJson(json));
    } else {
      // إذا لم تكن Map، فهذا تنسيق استجابة غير متوقع لهذا المسار
      // يمكن رمي استثناء يوضح المشكلة
      throw ApiException(response.statusCode, 'Received unexpected response format for managed articles. Expected a Map.', errors: null);
    }
  }

  /// إنشاء مقال جديد بواسطة الاستشاري
  Future<Article> createManagedArticle(String token, Map<String, dynamic> articleData) async {
    final response = await _post('/consultant/articles', articleData, token: token);
    return Article.fromJson(_handleResponse(response));
  }

  /// تحديث مقال بواسطة الاستشاري
  Future<Article> updateManagedArticle(String token, int articleId, Map<String, dynamic> articleData) async {
    final response = await _put('/consultant/articles/$articleId', articleData, token: token);
    return Article.fromJson(_handleResponse(response));
  }

  /// حذف مقال بواسطة الاستشاري
  Future<void> deleteManagedArticle(String token, int articleId) async {
    final response = await _delete('/consultant/articles/$articleId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  // --- 6. Admin Endpoints ---
  /// جلب مهارة واحدة بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/skills/{skillId}
  Future<Skill> fetchSingleSkillAdmin(String token, int skillId) async {
    final response = await _get('/admin/skills/$skillId', token: token);
    // يجب أن يعيد المتحكم بيانات المهارة في حالة النجاح (200 OK)
    return Skill.fromJson(_handleResponse(response));
  }

  /// جلب مجموعة واحدة بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/groups/{groupId}
  Future<Group> fetchSingleGroupAdmin(String token, int groupId) async {
    final response = await _get('/admin/groups/$groupId', token: token);
    // يجب أن يعيد المتحكم بيانات المجموعة في حالة النجاح (200 OK)
    return Group.fromJson(_handleResponse(response));
  }

  /// جلب شركة واحدة بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/companies/{companyId}
  Future<Company> fetchSingleCompanyAdmin(String token, int companyId) async {
    final response = await _get('/admin/companies/$companyId', token: token);
    // يجب أن يعيد المتحكم بيانات الشركة في حالة النجاح (200 OK)
    return Company.fromJson(_handleResponse(response));
  }

  /// جلب فرصة عمل واحدة بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/jobs/{jobId}
  Future<JobOpportunity> fetchSingleJobAdmin(String token, int jobId) async {
    final response = await _get('/admin/jobs/$jobId', token: token);
    // يجب أن يعيد المتحكم بيانات فرصة العمل في حالة النجاح (200 OK)
    return JobOpportunity.fromJson(_handleResponse(response));
  }

  /// جلب دورة تدريبية واحدة بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/courses/{courseId}
  Future<TrainingCourse> fetchSingleCourseAdmin(String token, int courseId) async {
    final response = await _get('/admin/courses/$courseId', token: token);
    // يجب أن يعيد المتحكم بيانات الدورة في حالة النجاح (200 OK)
    return TrainingCourse.fromJson(_handleResponse(response));
  }



  /// جلب مقال واحد بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/articles/{articleId}
  Future<Article> fetchSingleArticleAdmin(String token, int articleId) async {
    final response = await _get('/admin/articles/$articleId', token: token);
    // يجب أن يعيد المتحكم بيانات المقال في حالة النجاح (200 OK)
    return Article.fromJson(_handleResponse(response));
  }


  /// جلب مستخدم واحد بواسطة الأدمن
  /// يرسل طلب GET إلى /admin/users/{userId}
  Future<User> fetchSingleUserAdmin(String token, int userId) async {
    final response = await _get('/admin/users/$userId', token: token);
    // يجب أن يعيد المتحكم بيانات المستخدم في حالة النجاح (200 OK)
    return User.fromJson(_handleResponse(response));
  }

  /// جلب جميع المستخدمين (للأدمن)
  Future<PaginatedResponse<User>> fetchAllUsers(String token, {int page = 1}) async {
    final response = await _get('/admin/users?page=$page', token: token);
    return PaginatedResponse<User>.fromJson(_handleResponse(response), (json) => User.fromJson(json));
  }

  /// إنشاء مستخدم جديد (بواسطة الأدمن)
  Future<User> createNewUser(String token, Map<String, dynamic> userData) async {
    final response = await _post('/admin/users', userData, token: token);
    return User.fromJson(_handleResponse(response));
  }

  /// تحديث مستخدم (بواسطة الأدمن)
  Future<User> updateUser(String token, int userId, Map<String, dynamic> userData) async {
    final response = await _put('/admin/users/$userId', userData, token: token);
    return User.fromJson(_handleResponse(response));
  }

  /// حذف مستخدم (بواسطة الأدمن)
  Future<void> deleteUser(String token, int userId) async {
    final response = await _delete('/admin/users/$userId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب جميع المهارات (لإدارة الأدمن)
  Future<List<Skill>> fetchAllSkillsAdmin(String token) async {
    final response = await _get('/admin/skills', token: token);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => Skill.fromJson(json)).toList();
  }

  /// إنشاء مهارة جديدة (بواسطة الأدمن)
  Future<Skill> createSkill(String token, String skillName) async {
    final body = {'Name': skillName};
    final response = await _post('/admin/skills', body, token: token);
    return Skill.fromJson(_handleResponse(response));
  }

  /// تحديث مهارة (بواسطة الأدمن)
  Future<Skill> updateSkill(String token, int skillId, String newSkillName) async {
    final body = {'Name': newSkillName};
    final response = await _put('/admin/skills/$skillId', body, token: token);
    return Skill.fromJson(_handleResponse(response));
  }

  /// حذف مهارة (بواسطة الأدمن)
  Future<void> deleteSkill(String token, int skillId) async {
    final response = await _delete('/admin/skills/$skillId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب جميع المجموعات (لإدارة الأدمن)
  Future<List<Group>> fetchAllGroupsAdmin(String token) async {
    final response = await _get('/admin/groups', token: token);
    final List<dynamic> data = _handleResponse(response);
    return data.map((json) => Group.fromJson(json)).toList();
  }

  /// إنشاء مجموعة (بواسطة الأدمن)
  Future<Group> createGroup(String token, String telegramLink) async {
    final body = {'Telegram Hyper Link': telegramLink};
    final response = await _post('/admin/groups', body, token: token);
    return Group.fromJson(_handleResponse(response));
  }

  /// تحديث مجموعة (بواسطة الأدمن)
  Future<Group> updateGroup(String token, int groupId, String newTelegramLink) async {
    final body = {'Telegram Hyper Link': newTelegramLink};
    final response = await _put('/admin/groups/$groupId', body, token: token);
    return Group.fromJson(_handleResponse(response));
  }

  /// حذف مجموعة (بواسطة الأدمن)
  Future<void> deleteGroup(String token, int groupId) async {
    final response = await _delete('/admin/groups/$groupId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب جميع الشركات (لإدارة الأدمن)
  Future<PaginatedResponse<Company>> fetchAllCompaniesAdmin(String token, {int page = 1}) async {
    final response = await _get('/admin/companies?page=$page', token: token);
    return PaginatedResponse<Company>.fromJson(_handleResponse(response), (json) => Company.fromJson(json));
  }

  /// إنشاء شركة (بواسطة الأدمن)
  Future<Company> createCompanyAdmin(String token, Map<String, dynamic> companyData) async {
    final response = await _post('/admin/companies', companyData, token: token);
    return Company.fromJson(_handleResponse(response));
  }

  /// تحديث شركة (بواسطة الأدمن)
  Future<Company> updateCompanyAdmin(String token, int companyId, Map<String, dynamic> companyData) async {
    final response = await _put('/admin/companies/$companyId', companyData, token: token);
    return Company.fromJson(_handleResponse(response));
  }

  /// حذف شركة (بواسطة الأدمن)
  Future<void> deleteCompanyAdmin(String token, int companyId) async {
    final response = await _delete('/admin/companies/$companyId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب جميع المقالات (لإدارة الأدمن)
  Future<PaginatedResponse<Article>> fetchAllArticlesAdmin(String token, {int page = 1}) async {
    final response = await _get('/admin/articles?page=$page', token: token);
    return PaginatedResponse<Article>.fromJson(_handleResponse(response), (json) => Article.fromJson(json));
  }

  /// إنشاء مقال (بواسطة الأدمن)
  Future<Article> createArticleAdmin(String token, Map<String, dynamic> articleData) async {
    final response = await _post('/admin/articles', articleData, token: token);
    return Article.fromJson(_handleResponse(response));
  }

  /// تحديث مقال (بواسطة الأدمن)
  Future<Article> updateArticleAdmin(String token, int articleId, Map<String, dynamic> articleData) async {
    final response = await _put('/admin/articles/$articleId', articleData, token: token);
    return Article.fromJson(_handleResponse(response));
  }

  /// حذف مقال (بواسطة الأدمن)
  Future<void> deleteArticleAdmin(String token, int articleId) async {
    final response = await _delete('/admin/articles/$articleId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب جميع فرص العمل (لإدارة الأدمن)
  Future<PaginatedResponse<JobOpportunity>> fetchAllJobsAdmin(String token, {int page = 1}) async {
    final response = await _get('/admin/jobs?page=$page', token: token);
    return PaginatedResponse<JobOpportunity>.fromJson(_handleResponse(response), (json) => JobOpportunity.fromJson(json));
  }

  /// إنشاء فرصة عمل (بواسطة الأدمن)
  Future<JobOpportunity> createJobAdmin(String token, Map<String, dynamic> jobData) async {
    final response = await _post('/admin/jobs', jobData, token: token);
    return JobOpportunity.fromJson(_handleResponse(response));
  }

  /// تحديث فرصة عمل (بواسطة الأدمن)
  Future<JobOpportunity> updateJobAdmin(String token, int jobId, Map<String, dynamic> jobData) async {
    final response = await _put('/admin/jobs/$jobId', jobData, token: token);
    return JobOpportunity.fromJson(_handleResponse(response));
  }

  /// حذف فرصة عمل (بواسطة الأدمن)
  Future<void> deleteJobAdmin(String token, int jobId) async {
    final response = await _delete('/admin/jobs/$jobId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب جميع الدورات (لإدارة الأدمن)
  Future<PaginatedResponse<TrainingCourse>> fetchAllCoursesAdmin(String token, {int page = 1}) async {
    final response = await _get('/admin/courses?page=$page', token: token);
    return PaginatedResponse<TrainingCourse>.fromJson(_handleResponse(response), (json) => TrainingCourse.fromJson(json));
  }

  /// إنشاء دورة (بواسطة الأدمن)
  Future<TrainingCourse> createCourseAdmin(String token, Map<String, dynamic> courseData) async {
    final response = await _post('/admin/courses', courseData, token: token);
    return TrainingCourse.fromJson(_handleResponse(response));
  }

  /// تحديث دورة (بواسطة الأدمن)
  Future<TrainingCourse> updateCourseAdmin(String token, int courseId, Map<String, dynamic> courseData) async {
    final response = await _put('/admin/courses/$courseId', courseData, token: token);
    return TrainingCourse.fromJson(_handleResponse(response));
  }

  /// حذف دورة (بواسطة الأدمن)
  Future<void> deleteCourseAdmin(String token, int courseId) async {
    final response = await _delete('/admin/courses/$courseId', token: token);
    _handleResponse(response); // Expected 204 No Content
  }

  /// جلب طلبات إنشاء الشركات المعلقة (لأدمن)
  Future<PaginatedResponse<Company>> fetchCompanyRequests(String token, {int page = 1}) async {
    final response = await _get('/admin/company-requests?page=$page', token: token);
    // Note: The Company model might need to include a 'user' property if your API returns it here
    return PaginatedResponse<Company>.fromJson(_handleResponse(response), (json) => Company.fromJson(json));
  }

  /// الموافقة على طلب شركة (بواسطة الأدمن)
  Future<Company> approveCompanyRequest(String token, int companyId) async {
    final response = await _put('/admin/company-requests/$companyId/approve', {}, token: token); // Body is empty
    // Note: The response body might only contain a message or the updated company
    return Company.fromJson(_handleResponse(response)['company']); // Assuming it returns {'message': '...', 'company': {...}}
  }

  /// رفض طلب شركة (بواسطة الأدمن)
  Future<Company> rejectCompanyRequest(String token, int companyId) async {
    final response = await _put('/admin/company-requests/$companyId/reject', {}, token: token); // Body is empty
    // Note: The response body might only contain a message or the updated company
    return Company.fromJson(_handleResponse(response)['company']); // Assuming it returns {'message': '...', 'company': {...}}
  }


  // ... (باقي كود ApiService قبل هذا) ...

  // --- 6. Admin Endpoints ---
  // ... (existing admin CRUD methods) ...


  /// جلب فرص العمل لشركة محددة بواسطة الأدمن
  /// يرسل طلب GET إلى مسار API في Backend يجلب الوظائف بفلتر الشركة.
  /// **تحقق من Backend:** ما هو المسار الدقيق وطريقة الطلب (GET) لجلب وظائف شركة معينة بواسطة الأدمن؟
  /// الأمثلة المحتملة للمسار:
  /// - GET /admin/companies/{companyId}/jobs (مسار nested resource)
  /// - GET /admin/jobs?company_id={companyId} (مسار مع فلتر كـ query parameter)
  ///
  /// هذا التابع يفترض مساراً معيناً وسيتطلب تعديلاً إذا كان المسار الفعلي مختلفاً في Backend.
  ///
  Future<PaginatedResponse<JobOpportunity>> fetchJobsByCompanyAdmin(String token, int companyId, {int page = 1}) async {
    // **المسار الافتراضي المستخدم هنا:** GET /admin/jobs?company_id={companyId}
    // **تحقق من backend للتأكد من المسار الصحيح.**
    // إذا كان المسار هو /admin/companies/{companyId}/jobs، يجب تغيير السطر التالي
    final endpoint = '/admin/jobs?company_id=$companyId&page=$page'; // مثال مع query parameter company_id و pagination

    final response = await _get(endpoint, token: token);

    // يجب أن يعيد المتحكم استجابة Pagination في حالة النجاح (200 OK)
    // _handleResponse سيعالج الأخطاء ويفك ترميز JSON
    // PaginatedResponse.fromJson سيحول البيانات إلى PaginatedResponse<JobOpportunity>
    final dynamic decodedBody = _handleResponse(response);

    // تحقق صريح للتأكد من أن الاستجابة هي Map (كما هو متوقع لـ PaginatedResponse)
    if (decodedBody is Map<String, dynamic>) {
      return PaginatedResponse<JobOpportunity>.fromJson(decodedBody, (json) => JobOpportunity.fromJson(json));
    } else {
      // إذا لم تكن Map، فهذا تنسيق استجابة غير متوقع
      throw ApiException(response.statusCode, 'Received unexpected response format for jobs by company. Expected a Map.', errors: null);
    }
  }


// ... (باقي توابع ApiService) ...


}