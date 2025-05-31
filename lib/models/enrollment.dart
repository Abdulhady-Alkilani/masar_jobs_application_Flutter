import 'training_course.dart'; // Assuming you load the course details

class Enrollment {
  final int? enrollmentId;
  final int? userId;
  final int? courseId;
  final String? status; // 'مكتمل', 'قيد التقدم', 'ملغي'
  final DateTime? date; // Enrollment date
  final DateTime? completDate; // Completion date
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TrainingCourse? trainingCourse; // Nested course details

  Enrollment({
    this.enrollmentId,
    this.userId,
    this.courseId,
    this.status,
    this.date,
    this.completDate,
    this.createdAt,
    this.updatedAt,
    this.trainingCourse,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    // Note: JSON key has spaces
    return Enrollment(
      enrollmentId: json['EnrollmentID'] as int?,
      userId: json['UserID'] as int?,
      courseId: json['CourseID'] as int?,
      status: json['Status'] as String?,
      date: json['Date'] != null ? DateTime.parse(json['Date'] as String) : null,
      completDate: json['Complet Date'] != null ? DateTime.parse(json['Complet Date'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      trainingCourse: json['training_course'] != null && json['training_course'] is Map<String, dynamic>
          ? TrainingCourse.fromJson(json['training_course'] as Map<String, dynamic>) // This might need a *partial* course model
          : null,
    );
  }

// Optional: toJson for enrolling in a course (usually just sending course ID, but handled by URL structure)
// Map<String, dynamic> toJson() { ... } // Not typically needed for enroll action body
}