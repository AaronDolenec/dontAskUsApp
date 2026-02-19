/// Model for individual answer detail entries returned by the API.
///
/// Each entry represents one group member's answer to a question,
/// including their avatar info for display.
class AnswerDetail {
  final String displayName;

  /// The member's answer. String for single-select, `List<String>` for
  /// multi-select, or the text answer for free_text questions.
  final dynamic answer;

  /// Free-text response (only present for free_text questions).
  final String? textAnswer;

  /// Hex color fallback avatar (e.g. "#FF6B6B").
  final String colorAvatar;

  /// Full URL to uploaded avatar image, or null.
  final String? avatarUrl;

  AnswerDetail({
    required this.displayName,
    this.answer,
    this.textAnswer,
    required this.colorAvatar,
    this.avatarUrl,
  });

  /// The answer as a simple string (for single-select / binary / free_text).
  String? get answerString {
    if (answer is String) return answer as String;
    if (answer is List && (answer as List).isNotEmpty) {
      return (answer as List).join(', ');
    }
    return textAnswer;
  }

  /// The answer as a list (for multi-select).
  List<String>? get answerList {
    if (answer is List) return (answer as List).cast<String>();
    if (answer is String) return [answer as String];
    return null;
  }

  /// Get initials from display name.
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName
        .substring(0, displayName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  factory AnswerDetail.fromJson(Map<String, dynamic> json) {
    return AnswerDetail(
      displayName: json['display_name'] as String? ?? '',
      answer: json['answer'],
      textAnswer: json['text_answer'] as String?,
      colorAvatar: json['color_avatar'] as String? ?? '#666666',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'answer': answer,
      'text_answer': textAnswer,
      'color_avatar': colorAvatar,
      'avatar_url': avatarUrl,
    };
  }

  @override
  String toString() {
    return 'AnswerDetail(displayName: $displayName, answer: $answer)';
  }
}

/// Model for text answer entries (simplified structure for free_text questions).
class TextAnswerEntry {
  final String displayName;
  final String textAnswer;
  final String colorAvatar;
  final String? avatarUrl;

  TextAnswerEntry({
    required this.displayName,
    required this.textAnswer,
    required this.colorAvatar,
    this.avatarUrl,
  });

  /// Get initials from display name.
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName
        .substring(0, displayName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  factory TextAnswerEntry.fromJson(Map<String, dynamic> json) {
    return TextAnswerEntry(
      displayName: json['display_name'] as String? ?? '',
      textAnswer: json['text_answer'] as String? ?? '',
      colorAvatar: json['color_avatar'] as String? ?? '#666666',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'text_answer': textAnswer,
      'color_avatar': colorAvatar,
      'avatar_url': avatarUrl,
    };
  }
}
