import 'user.dart'; // Or import 'partial_user.dart';

class TrainingCourse {
  final int? courseId;
  final int? userId; // User who created (Manager/Consultant/Admin)
  final String? courseName;
  final String? trainersName;
  final String? courseDescription;
  final String? site; // 'حضوري' or 'اونلاين'
  final String? trainersSite; // Training provider/platform
  final DateTime? startDate;
  final DateTime? endDate;
  final String? enrollHyperLink;
  final String? stage; // 'مبتدئ', 'متوسط', 'متقدم'
  final String? certificate; // 'يوجد' or 'لا يوجد'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PartialUser? creator; // Nested user object (often partial in lists)

  TrainingCourse({
    this.courseId,
    this.userId,
    this.courseName,
    this.trainersName,
    this.courseDescription,
    this.site,
    this.trainersSite,
    this.startDate,
    this.endDate,
    this.enrollHyperLink,
    this.stage,
    this.certificate,
    this.createdAt,
    this.updatedAt,
    this.creator,
  });

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    // Note: JSON keys might have spaces or unconventional names
    return TrainingCourse(
      courseId: json['CourseID'] as int?,
      userId: json['UserID'] as int?,
      courseName: json['Course name'] as String?,
      trainersName: json['Trainers name'] as String?,
      courseDescription: json['Course Description'] as String?,
      site: json['Site'] as String?,
      trainersSite: json['Trainers Site'] as String?,
      startDate: json['Start Date'] != null ? DateTime.parse(json['Start Date'] as String) : null,
      endDate: json['End Date'] != null ? DateTime.parse(json['End Date'] as String) : null,
      enrollHyperLink: json['Enroll Hyper Link'] as String?,
      stage: json['Stage'] as String?,
      certificate: json['Certificate'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      creator: json['creator'] != null && json['creator'] is Map<String, dynamic>
          ? PartialUser.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
    );
  }

  // Optional: toJson for creating/updating courses (Manager/Consultant/Admin)
  Map<String, dynamic> toJson() {
    // Note: JSON keys might have spaces or unconventional names
    return {
      'CourseID': courseId,
      'UserID': userId, // Needed for Admin creation
      'Course name': courseName,
      'Trainers name': trainersName,
      'Course Description': courseDescription,
      'Site': site,
      'Trainers Site': trainersSite,
      'Start Date': startDate?.toIso8601String(),
      'End Date': endDate?.toIso8601String(),
      'Enroll Hyper Link': enrollHyperLink,
      'Stage': stage,
      'Certificate': certificate,
      // created_at, updated_at, creator not sent back
    };
  }
}