import 'user.dart'; // Or import 'partial_user.dart'; if the nested user is always partial

class Article {
  final int? articleId;
  final int? userId;
  final String? title;
  final String? description;
  final DateTime? date; // Publish date
  final String? type;
  final String? articlePhoto;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PartialUser? user; // Nested user object (often partial in lists)

  Article({
    this.articleId,
    this.userId,
    this.title,
    this.description,
    this.date,
    this.type,
    this.articlePhoto,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    // Note: JSON keys might have spaces or unconventional names
    return Article(
      articleId: json['ArticleID'] as int?,
      userId: json['UserID'] as int?,
      title: json['Title'] as String?,
      description: json['Description'] as String?,
      date: json['Date'] != null ? DateTime.parse(json['Date'] as String) : null,
      type: json['Type'] as String?,
      articlePhoto: json['Article Photo'] as String?,
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

  // Optional: toJson for creating/updating articles (Consultant/Admin)
  Map<String, dynamic> toJson() {
    // Note: JSON keys might have spaces or unconventional names
    return {
      'ArticleID': articleId,
      'UserID': userId, // Needed for Admin creation
      'Title': title,
      'Description': description,
      'Date': date?.toIso8601String(),
      'Type': type,
      'Article Photo': articlePhoto,
      // created_at, updated_at, user not sent back
    };
  }
}