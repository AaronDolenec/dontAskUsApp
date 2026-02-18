import 'question_type.dart';

/// DailyQuestion model representing today's question
class DailyQuestion {
  final int id;
  final String questionId;
  final String questionText;
  final QuestionType questionType;
  final List<String>? options;
  final Map<String, int>? optionCounts;
  final DateTime questionDate;
  final bool isActive;
  final int totalVotes;
  final bool allowMultiple;
  final dynamic userVote; // String or List<String> or null
  final String? userTextAnswer;
  final int userStreak;
  final int longestStreak;

  DailyQuestion({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.options,
    this.optionCounts,
    required this.questionDate,
    required this.isActive,
    this.totalVotes = 0,
    this.allowMultiple = false,
    this.userVote,
    this.userTextAnswer,
    this.userStreak = 0,
    this.longestStreak = 0,
  });

  /// Check if the user has already voted/answered
  bool get hasUserVoted => userVote != null || userTextAnswer != null;

  /// Get the user's vote as a string (for single choice)
  String? get userVoteString {
    if (userVote is String) return userVote as String;
    return null;
  }

  /// Get the user's votes as a list (for multiple choice)
  List<String>? get userVoteList {
    if (userVote is List) {
      return (userVote as List).cast<String>();
    }
    if (userVote is String) {
      return [userVote as String];
    }
    return null;
  }

  /// Get the winning option (option with most votes)
  String? get winningOption {
    if (optionCounts == null || optionCounts!.isEmpty) return null;

    String? winner;
    int maxVotes = 0;

    for (final entry in optionCounts!.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winner = entry.key;
      }
    }

    return winner;
  }

  /// Get vote percentage for an option
  double getVotePercentage(String option) {
    if (totalVotes == 0 || optionCounts == null) return 0.0;
    final count = optionCounts![option] ?? 0;
    return (count / totalVotes) * 100;
  }

  factory DailyQuestion.fromJson(Map<String, dynamic> json) {
    return DailyQuestion(
      id: json['id'] as int? ?? 0,
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType:
          QuestionTypeExtension.fromString(json['question_type'] as String),
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      optionCounts: json['option_counts'] != null
          ? Map<String, int>.from(json['option_counts'] as Map)
          : null,
      questionDate: DateTime.parse(json['question_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      totalVotes: json['total_votes'] as int? ?? 0,
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      userVote: json['user_vote'],
      userTextAnswer: json['user_text_answer'] as String?,
      userStreak: json['user_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'question_text': questionText,
      'question_type': questionType.apiValue,
      'options': options,
      'option_counts': optionCounts,
      'question_date': questionDate.toIso8601String(),
      'is_active': isActive,
      'total_votes': totalVotes,
      'allow_multiple': allowMultiple,
      'user_vote': userVote,
      'user_text_answer': userTextAnswer,
      'user_streak': userStreak,
      'longest_streak': longestStreak,
    };
  }

  DailyQuestion copyWith({
    int? id,
    String? questionId,
    String? questionText,
    QuestionType? questionType,
    List<String>? options,
    Map<String, int>? optionCounts,
    DateTime? questionDate,
    bool? isActive,
    int? totalVotes,
    bool? allowMultiple,
    dynamic userVote,
    String? userTextAnswer,
    int? userStreak,
    int? longestStreak,
  }) {
    return DailyQuestion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      optionCounts: optionCounts ?? this.optionCounts,
      questionDate: questionDate ?? this.questionDate,
      isActive: isActive ?? this.isActive,
      totalVotes: totalVotes ?? this.totalVotes,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      userVote: userVote ?? this.userVote,
      userTextAnswer: userTextAnswer ?? this.userTextAnswer,
      userStreak: userStreak ?? this.userStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  @override
  String toString() {
    return 'DailyQuestion(id: $id, text: $questionText, type: ${questionType.displayName})';
  }
}
