/// Session validation response model
class SessionValidation {
  final bool valid;
  final String? oderId;
  final String? displayName;
  final String? groupId;
  final int? answerStreak;
  final int? longestAnswerStreak;

  SessionValidation({
    required this.valid,
    this.oderId,
    this.displayName,
    this.groupId,
    this.answerStreak,
    this.longestAnswerStreak,
  });

  factory SessionValidation.fromJson(Map<String, dynamic> json) {
    return SessionValidation(
      valid: json['valid'] as bool,
      oderId: json['user_id'] as String?,
      displayName: json['display_name'] as String?,
      groupId: json['group_id'] as String?,
      answerStreak: json['answer_streak'] as int?,
      longestAnswerStreak: json['longest_answer_streak'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'user_id': oderId,
      'display_name': displayName,
      'group_id': groupId,
      'answer_streak': answerStreak,
      'longest_answer_streak': longestAnswerStreak,
    };
  }
}
