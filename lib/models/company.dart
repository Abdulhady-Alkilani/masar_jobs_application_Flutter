// lib/models/company.dart

import 'user.dart';

class Company {
  final int? companyId;
  final int? userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? description;
  final String? country;
  final String? city;
  final String? detailedAddress;
  final String? media;
  final String? webSite;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;

  // --- الحقول الجديدة ---
  final int? newApplicantsCount;
  final int? openJobsCount;

  Company({
    this.companyId,
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.description,
    this.country,
    this.city,
    this.detailedAddress,
    this.media,
    this.webSite,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.user,
    // --- إضافة الحقول إلى الباني ---
    this.newApplicantsCount,
    this.openJobsCount,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      companyId: json['CompanyID'] as int?,
      userId: json['UserID'] as int?,
      name: json['Name'] as String?,
      email: json['Email'] as String?,
      phone: json['Phone'] as String?,
      description: json['Description'] as String?,
      country: json['Country'] as String?,
      city: json['City'] as String?,
      detailedAddress: json['Detailed Address'] as String?,
      media: json['Media'] as String?,
      webSite: json['Web site'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      // --- فك ترميز الحقول من الـ JSON ---
      // تأكد من أن الـ API يرسل حقولاً بهذه الأسماء
      newApplicantsCount: json['new_applicants_count'] as int?,
      openJobsCount: json['open_jobs_count'] as int?,
    );
  }

// ... toJson method ...
}