import 'answer_detail.dart';

/// AnswerResponse model for vote/answer submission results
class AnswerResponse {
  final bool success;
  final String? questionType;
  final List<String>? options;
  final Map<String, int>? optionCounts;
  final int totalVotes;
  final dynamic userAnswer;
  final int currentStreak;
  final int longestStreak;

  /// Who answered what — returned for every question type after submission.
  final List<AnswerDetail>? answerDetails;

  /// All free-text answers (only for free_text questions).
  final List<TextAnswerEntry>? textAnswers;

  /// Display name of the randomly chosen member if {member} placeholder was
  /// used, otherwise null.
  final String? featuredMember;

  AnswerResponse({
    required this.success,
    this.questionType,
    this.options,
    this.optionCounts,
    required this.totalVotes,
    this.userAnswer,
    required this.currentStreak,
    required this.longestStreak,
    this.answerDetails,
    this.textAnswers,
    this.featuredMember,
  });

  /// Check if the submission was successful
  bool get isSuccess => success;

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      success: json['success'] as bool? ?? true,
      questionType: json['question_type'] as String?,
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
      answerDetails: json['answer_details'] != null
          ? (json['answer_details'] as List)
              .map((e) => AnswerDetail.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      textAnswers: json['text_answers'] != null
          ? (json['text_answers'] as List)
              .map((e) => TextAnswerEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      featuredMember: json['featured_member'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'question_type': questionType,
      'options': options,
      'option_counts': optionCounts,
      'total_votes': totalVotes,
      'user_answer': userAnswer,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'answer_details': answerDetails?.map((e) => e.toJson()).toList(),
      'text_answers': textAnswers?.map((e) => e.toJson()).toList(),
      'featured_member': featuredMember,
    };
  }

  @override
  String toString() {
    return 'AnswerResponse(success: $success, streak: $currentStreak)';
  }
}
