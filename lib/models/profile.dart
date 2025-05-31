class Profile {
  final int? profileId;
  final int? userId;
  final String? university;
  final String? gpa;
  final String? personalDescription;
  final String? technicalDescription;
  final String? gitHyperLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    this.profileId,
    this.userId,
    this.university,
    this.gpa,
    this.personalDescription,
    this.technicalDescription,
    this.gitHyperLink,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Note: JSON keys have spaces or unconventional names - map them correctly
    return Profile(
      profileId: json['ProfileID'] as int?,
      userId: json['UserID'] as int?,
      university: json['University'] as String?,
      gpa: json['GPA'] as String?,
      personalDescription: json['Personal Description'] as String?,
      technicalDescription: json['Technical Description'] as String?,
      gitHyperLink: json['Git Hyper Link'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Optional: toJson for sending profile updates
  Map<String, dynamic> toJson() {
    // Note: JSON keys have spaces or unconventional names - map them correctly
    return {
      'ProfileID': profileId,
      'UserID': userId,
      'University': university,
      'GPA': gpa,
      'Personal Description': personalDescription,
      'Technical Description': technicalDescription,
      'Git Hyper Link': gitHyperLink,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}