/// Group model representing a dontAskUs group
class Group {
  final int id;
  final String groupId;
  final String name;
  final String inviteCode;
  final DateTime createdAt;
  final int memberCount;

  Group({
    required this.id,
    required this.groupId,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
    };
  }

  Group copyWith({
    int? id,
    String? groupId,
    String? name,
    String? inviteCode,
    DateTime? createdAt,
    int? memberCount,
  }) {
    return Group(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, members: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.groupId == groupId;
  }

  @override
  int get hashCode => groupId.hashCode;
}
