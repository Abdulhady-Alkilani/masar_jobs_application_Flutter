import 'user_skill_pivot.dart'; // Assuming you might model the pivot data

class Skill {
  final int? skillId;
  final String? name;
  final UserSkillPivot? pivot; // Added to hold pivot data when loading skills ON a user

  Skill({this.skillId, this.name, this.pivot});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      skillId: json['SkillID'] as int?,
      name: json['Name'] as String?,
      // Parse pivot data if it exists in the JSON response (e.g., from user.skills)
      pivot: json['pivot'] != null && json['pivot'] is Map<String, dynamic>
          ? UserSkillPivot.fromJson(json['pivot'] as Map<String, dynamic>)
          : null,
    );
  }

  // Optional: toJson for sending skill data (e.g., creating a skill - Admin)
  Map<String, dynamic> toJson() {
    return {
      'SkillID': skillId,
      'Name': name,
      // Pivot data is usually not sent back in the skill object itself
    };
  }
}