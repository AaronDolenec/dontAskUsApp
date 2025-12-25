/// GroupMember model for displaying members in a group
class GroupMember {
  final String oderId;
  final String displayName;
  final String colorAvatar;
  final int answerStreak;
  final int longestAnswerStreak;

  GroupMember({
    required this.oderId,
    required this.displayName,
    required this.colorAvatar,
    this.answerStreak = 0,
    this.longestAnswerStreak = 0,
  });

  /// Get initials from display name (first 1-2 characters)
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      oderId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      colorAvatar: json['color_avatar'] as String? ?? '#3B82F6',
      answerStreak: json['answer_streak'] as int? ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'display_name': displayName,
      'color_avatar': colorAvatar,
      'answer_streak': answerStreak,
      'longest_answer_streak': longestAnswerStreak,
    };
  }

  GroupMember copyWith({
    String? oderId,
    String? displayName,
    String? colorAvatar,
    int? answerStreak,
    int? longestAnswerStreak,
  }) {
    return GroupMember(
      oderId: oderId ?? this.oderId,
      displayName: displayName ?? this.displayName,
      colorAvatar: colorAvatar ?? this.colorAvatar,
      answerStreak: answerStreak ?? this.answerStreak,
      longestAnswerStreak: longestAnswerStreak ?? this.longestAnswerStreak,
    );
  }

  @override
  String toString() {
    return 'GroupMember(displayName: $displayName, streak: $answerStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.oderId == oderId;
  }

  @override
  int get hashCode => oderId.hashCode;
}
