import 'profile.dart';
import 'skill.dart';
import 'company.dart';

class User {
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final bool? emailVerified; // Changed from int 1/0 to bool
  final String? phone;
  final String? photo;
  final String? status;
  final String? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Profile? profile;
  final List<Skill>? skills; // Skills with pivot data
  final Company? company; // Company managed by the user

  User({
    this.userId,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.emailVerified,
    this.phone,
    this.photo,
    this.status,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.profile,
    this.skills,
    this.company,
  });

  // تابع copyWith لتحديث جزئي لكائن المستخدم
  User copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    bool? emailVerified,
    String? phone,
    String? photo,
    String? status,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? profile, // <--- هذا هو الحقل الذي نريد تحديثه
    List<Skill>? skills,
    Company? company,
  }) {
    // ينشئ كائن User جديد باستخدام القيم الجديدة إذا تم تمريرها، أو القيم الحالية إذا لم يتم تمريرها
    return User(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile, // تحديث حقل profile هنا
      skills: skills ?? this.skills,
      company: company ?? this.company,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['UserID'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] == 1, // Convert 1/0 to bool
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
      status: json['status'] as String?,
      type: json['type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      profile: json['profile'] != null && json['profile'] is Map<String, dynamic>
          ? Profile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((s) => Skill.fromJson(s as Map<String, dynamic>))
          .toList(),
      company: json['company'] != null && json['company'] is Map<String, dynamic>
          ? Company.fromJson(json['company'] as Map<String, dynamic>)
          : null,
    );
  }

  // Optional: toJson method for sending user data (e.g., profile update)
  Map<String, dynamic> toJson() {
    return {
      'UserID': userId,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'email_verified': emailVerified,
      'phone': phone,
      'photo': photo,
      'status': status,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Profile, Skills, Company usually not sent back in full user update
    };
  }
}

// This might be needed for the partial User object returned in lists (Articles, Jobs, Courses)
class PartialUser {
  final int? userId;
  final String? firstName;
  final String? lastName;

  PartialUser({this.userId, this.firstName, this.lastName});

  factory PartialUser.fromJson(Map<String, dynamic> json) {
    return PartialUser(
      userId: json['UserID'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

}
