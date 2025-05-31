import 'user.dart'; // Or import 'partial_user.dart';

class JobOpportunity {
  final int? jobId;
  final int? userId; // User who posted (Company Manager/Admin)
  final String? jobTitle;
  final String? jobDescription;
  final String? qualification;
  final String? site; // Location
  final DateTime? date; // Publish Date
  final String? skills; // Note: This is a TEXT field in DB, could be comma-separated or JSON string
  final String? type; // 'وظيفة' or 'تدريب'
  final DateTime? endDate; // Application Deadline
  final String? status; // 'مفعل', 'معلق', 'محذوف'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PartialUser? user; // Nested user object (often partial in lists)

  JobOpportunity({
    this.jobId,
    this.userId,
    this.jobTitle,
    this.jobDescription,
    this.qualification,
    this.site,
    this.date,
    this.skills,
    this.type,
    this.endDate,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory JobOpportunity.fromJson(Map<String, dynamic> json) {
    // Note: JSON keys might have spaces or unconventional names
    return JobOpportunity(
      jobId: json['JobID'] as int?,
      userId: json['UserID'] as int?,
      jobTitle: json['Job Title'] as String?,
      jobDescription: json['Job Description'] as String?,
      qualification: json['Qualification'] as String?,
      site: json['Site'] as String?,
      date: json['Date'] != null ? DateTime.parse(json['Date'] as String) : null,
      skills: json['Skills'] as String?, // Keep as string as per DB schema
      type: json['Type'] as String?,
      endDate: json['End Date'] != null ? DateTime.parse(json['End Date'] as String) : null,
      status: json['Status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? PartialUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  // Optional: toJson for creating/updating jobs (Company Manager/Admin)
  Map<String, dynamic> toJson() {
    // Note: JSON keys might have spaces or unconventional names
    return {
      'JobID': jobId,
      'UserID': userId, // Needed for Admin creation
      'Job Title': jobTitle,
      'Job Description': jobDescription,
      'Qualification': qualification,
      'Site': site,
      'Date': date?.toIso8601String(),
      'Skills': skills,
      'Type': type,
      'End Date': endDate?.toIso8601String(),
      'Status': status,
      // created_at, updated_at, user not sent back
    };
  }
}