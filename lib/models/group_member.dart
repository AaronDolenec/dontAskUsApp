/// GroupMember model for displaying members in a group
class GroupMember {
  final String userId;
  final String displayName;
  final String colorAvatar;
  final String? avatarUrl;
  final int answerStreak;
  final int longestAnswerStreak;

  GroupMember({
    required this.userId,
    required this.displayName,
    required this.colorAvatar,
    this.avatarUrl,
    this.answerStreak = 0,
    this.longestAnswerStreak = 0,
  });

  /// Get initials from display name (first 1-2 characters)
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName
        .substring(0, displayName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      colorAvatar: json['color_avatar'] as String? ?? '#3B82F6',
      avatarUrl: json['avatar_url'] as String?,
      answerStreak: json['answer_streak'] as int? ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'color_avatar': colorAvatar,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'answer_streak': answerStreak,
      'longest_answer_streak': longestAnswerStreak,
    };
  }

  GroupMember copyWith({
    String? userId,
    String? displayName,
    String? colorAvatar,
    String? avatarUrl,
    int? answerStreak,
    int? longestAnswerStreak,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      colorAvatar: colorAvatar ?? this.colorAvatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      answerStreak: answerStreak ?? this.answerStreak,
      longestAnswerStreak: longestAnswerStreak ?? this.longestAnswerStreak,
    );
  }

  @override
  String toString() {
    return 'GroupMember(displayName: $displayName, userId: $userId, streak: $answerStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
