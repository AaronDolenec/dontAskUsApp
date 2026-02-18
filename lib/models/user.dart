/// User model representing a platform account and group membership
class User {
  final int id;
  final String oderId; // user_id within a group OR account_id
  final String displayName;
  final String colorAvatar;
  final String? avatarUrl;
  final String? email;
  final DateTime createdAt;
  final int answerStreak;
  final int longestAnswerStreak;
  final List<UserGroupMembership> groups;

  User({
    required this.id,
    required this.oderId,
    required this.displayName,
    required this.colorAvatar,
    this.avatarUrl,
    this.email,
    required this.createdAt,
    this.answerStreak = 0,
    this.longestAnswerStreak = 0,
    this.groups = const [],
  });

  /// Create from login/register response (flat auth response: account_id, display_name, email)
  factory User.fromAuthJson(Map<String, dynamic> json) {
    final groupsJson = json['groups'] as List? ?? [];
    final accountId = json['account_id']?.toString() ?? '0';
    return User(
      id: int.tryParse(accountId) ?? 0,
      oderId: accountId,
      displayName: json['display_name'] as String? ?? '',
      colorAvatar: json['color_avatar'] as String? ?? '#3B82F6',
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      answerStreak: json['answer_streak'] as int? ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] as int? ?? 0,
      groups: groupsJson
          .map((g) => UserGroupMembership.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Create from /api/auth/me response: {account: {...}, groups: [...]}
  factory User.fromMeJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>? ?? json;
    final groups = json['groups'] as List? ?? [];
    // Merge account fields + groups into a single map for fromAuthJson
    return User.fromAuthJson({
      ...account,
      'groups': groups,
    });
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both old session-token format and new JWT format
    final groupsJson = json['groups'] as List? ?? [];
    final accountId = json['account_id']?.toString();
    return User(
      id: json['id'] as int? ??
          (accountId != null ? int.tryParse(accountId) ?? 0 : 0),
      oderId: (json['user_id'] ?? accountId ?? '').toString(),
      displayName: json['display_name'] as String? ?? '',
      colorAvatar: json['color_avatar'] as String? ?? '#3B82F6',
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      answerStreak: json['answer_streak'] as int? ?? 0,
      longestAnswerStreak: json['longest_answer_streak'] as int? ?? 0,
      groups: groupsJson
          .map((g) => UserGroupMembership.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': id,
      'user_id': oderId,
      'display_name': displayName,
      'color_avatar': colorAvatar,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (email != null) 'email': email,
      'created_at': createdAt.toIso8601String(),
      'answer_streak': answerStreak,
      'longest_answer_streak': longestAnswerStreak,
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }

  User copyWith({
    int? id,
    String? oderId,
    String? displayName,
    String? colorAvatar,
    String? avatarUrl,
    String? email,
    DateTime? createdAt,
    int? answerStreak,
    int? longestAnswerStreak,
    List<UserGroupMembership>? groups,
  }) {
    return User(
      id: id ?? this.id,
      oderId: oderId ?? this.oderId,
      displayName: displayName ?? this.displayName,
      colorAvatar: colorAvatar ?? this.colorAvatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      answerStreak: answerStreak ?? this.answerStreak,
      longestAnswerStreak: longestAnswerStreak ?? this.longestAnswerStreak,
      groups: groups ?? this.groups,
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

/// Represents a user's membership in a group (from login/register response)
class UserGroupMembership {
  final String userId; // user_id within the group
  final String groupId;
  final String groupName;
  final String displayName;

  UserGroupMembership({
    required this.userId,
    required this.groupId,
    required this.groupName,
    required this.displayName,
  });

  factory UserGroupMembership.fromJson(Map<String, dynamic> json) {
    return UserGroupMembership(
      userId: (json['user_id'] ?? '').toString(),
      groupId: (json['group_id'] ?? '').toString(),
      groupName: json['group_name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'group_name': groupName,
      'display_name': displayName,
    };
  }
}
