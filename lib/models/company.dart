import 'user.dart'; // <--- 1. استيراد موديل المستخدم

class Company {
  final int? companyId;
  final int? userId; // Associated user ID (Company Manager)
  final String? name;
  final String? email;
  final String? phone;
  final String? description;
  final String? country;
  final String? city;
  final String? detailedAddress;
  final String? media; // Stored as string (path or JSON array string)
  final String? webSite;
  final String? status; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user; // <--- 2. إضافة حقل المستخدم المرتبط


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
    this.user, // <--- 3. إضافة الحقل للباني (Constructor)
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    // Note: JSON keys might have spaces or unconventional names
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // <--- 4. إضافة منطق فك ترميز حقل 'user'
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  // Optional: toJson for creating/updating companies (Admin/Manager)
  Map<String, dynamic> toJson() {
    // Note: JSON keys might have spaces or unconventional names
    return {
      'CompanyID': companyId,
      'UserID': userId,
      'Name': name,
      'Email': email,
      'Phone': phone,
      'Description': description,
      'Country': country,
      'City': city,
      'Detailed Address': detailedAddress,
      'Media': media,
      'Web site': webSite,
      'status': status,
    };
  }
}