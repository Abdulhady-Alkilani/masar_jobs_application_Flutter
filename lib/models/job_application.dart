import 'job_opportunity.dart'; // Assuming you load the job opportunity details

class JobApplication {
  final int? id; // Application ID
  final int? userId; // Applicant User ID
  final int? jobId; // Job Opportunity ID
  final String? status; // 'Pending', 'Reviewed', etc.
  final DateTime? date; // Application date
  final String? description; // Cover letter notes
  final String? cv; // Path to CV file
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final JobOpportunity? jobOpportunity; // Nested job details

  JobApplication({
    this.id,
    this.userId,
    this.jobId,
    this.status,
    this.date,
    this.description,
    this.cv,
    this.createdAt,
    this.updatedAt,
    this.jobOpportunity,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
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
      jobOpportunity: json['job_opportunity'] != null && json['job_opportunity'] is Map<String, dynamic>
          ? JobOpportunity.fromJson(json['job_opportunity'] as Map<String, dynamic>) // This might need a *partial* job model depending on the API response
          : null,
    );
  }

  // Optional: toJson for applying for a job
  Map<String, dynamic> toJson() {
    return {
      // ID, UserID, JobID, Status, Date are set by backend
      'Description': description,
      'CV': cv,
    };
  }
}