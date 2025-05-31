// Model specifically for the pivot data when loading skills *on* a user
class UserSkillPivot {
  final int? userId;
  final int? skillId;
  final String? stage;

  UserSkillPivot({this.userId, this.skillId, this.stage});

  factory UserSkillPivot.fromJson(Map<String, dynamic> json) {
    return UserSkillPivot(
      userId: json['UserID'] as int?,
      skillId: json['SkillID'] as int?,
      stage: json['Stage'] as String?,
    );
  }
}