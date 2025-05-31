class Group {
  final int? groupId;
  final String? telegramHyperLink;

  Group({this.groupId, this.telegramHyperLink});

  factory Group.fromJson(Map<String, dynamic> json) {
    // Note: JSON key has spaces
    return Group(
      groupId: json['GroupID'] as int?,
      telegramHyperLink: json['Telegram Hyper Link'] as String?,
    );
  }

  // Optional: toJson for creating/updating groups (Admin)
  Map<String, dynamic> toJson() {
    // Note: JSON key has spaces
    return {
      'GroupID': groupId,
      'Telegram Hyper Link': telegramHyperLink,
    };
  }
}