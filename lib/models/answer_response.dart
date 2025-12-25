/// AnswerResponse model for vote/answer submission results
class AnswerResponse {
  final String message;
  final String questionId;
  final List<String>? options;
  final Map<String, int>? optionCounts;
  final int totalVotes;
  final dynamic userAnswer;
  final int currentStreak;
  final int longestStreak;

  AnswerResponse({
    required this.message,
    required this.questionId,
    this.options,
    this.optionCounts,
    required this.totalVotes,
    this.userAnswer,
    required this.currentStreak,
    required this.longestStreak,
  });

  /// Check if the submission was successful
  bool get isSuccess => message.toLowerCase().contains('recorded') || 
                        message.toLowerCase().contains('success');

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      message: json['message'] as String,
      questionId: json['question_id'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      optionCounts: json['option_counts'] != null
          ? Map<String, int>.from(json['option_counts'] as Map)
          : null,
      totalVotes: json['total_votes'] as int? ?? 0,
      userAnswer: json['user_answer'],
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'question_id': questionId,
      'options': options,
      'option_counts': optionCounts,
      'total_votes': totalVotes,
      'user_answer': userAnswer,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
    };
  }

  @override
  String toString() {
    return 'AnswerResponse(message: $message, streak: $currentStreak)';
  }
}
