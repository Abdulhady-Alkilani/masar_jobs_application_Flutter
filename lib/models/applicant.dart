import 'user.dart'; // Use the main User model
import 'profile.dart'; // Import Profile as it's nested in User here

class Applicant {
  final int? id; // Application ID
  final int? userId; // Applicant User ID
  final int? jobId; // Job Opportunity ID
  final String? status; // 'Pending', 'Reviewed', etc.
  final DateTime? date; // Application date
  final String? description; // Cover letter notes
  final String? cv; // Path to CV file
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user; // Nested Applicant User object (might be fully loaded with profile)

  Applicant({
    this.id,
    this.userId,
    this.jobId,
    this.status,
    this.date,
    this.description,
    this.cv,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      id: json['ID'] as int?,
      userId: json['UserID'] as int?,
      jobId: json['JobID'] as int?,
      status: json['Status'] as String?,
      date: json['Date'] != null ? DateTime.parse(json['Date'] as String) : null,
      description: json['Description'] as String?,
      cv: json['CV'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>) // Assuming it's the full User model here
          : null,
    );
  }
}