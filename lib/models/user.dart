/// User model representing a group member
class User {
  final int id;
  final String oderId;
  final String displayName;
  final String colorAvatar;
  final String sessionToken;
  final DateTime createdAt;
  final int answerStreak;
  final int longestAnswerStreak;

  User({
    required this.id,
    required this.oderId,
    required this.displayName,
    required this.colorAvatar,
    required this.sessionToken,
    required this.createdAt,
    this.answerStreak = 0,
    this.longestAnswerStreak = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      oderId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      colorAvatar: json['color_avatar'] as String? ?? '#3B82F6',
      sessionToken: json['session_token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      answerStreak: json['answer_streak'] as int? ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'display_name': displayName,
      'color_avatar': colorAvatar,
      'session_token': sessionToken,
      'created_at': createdAt.toIso8601String(),
      'answer_streak': answerStreak,
      'longest_answer_streak': longestAnswerStreak,
    };
  }

  User copyWith({
    int? id,
    String? oderId,
    String? displayName,
    String? colorAvatar,
    String? sessionToken,
    DateTime? createdAt,
    int? answerStreak,
    int? longestAnswerStreak,
  }) {
    return User(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      displayName: displayName ?? this.displayName,
      colorAvatar: colorAvatar ?? this.colorAvatar,
      sessionToken: sessionToken ?? this.sessionToken,
      createdAt: createdAt ?? this.createdAt,
      answerStreak: answerStreak ?? this.answerStreak,
      longestAnswerStreak: longestAnswerStreak ?? this.longestAnswerStreak,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, displayName: $displayName, streak: $answerStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.oderId == oderId;
  }

  @override
  int get hashCode => oderId.hashCode;
}
