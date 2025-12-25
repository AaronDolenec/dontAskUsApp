/// Question types available in the app
enum QuestionType {
  binaryVote,
  singleChoice,
  freeText,
  memberChoice,
  duoChoice,
}

extension QuestionTypeExtension on QuestionType {
  /// Get the API string value for this question type
  String get apiValue {
    switch (this) {
      case QuestionType.binaryVote:
        return 'binary_vote';
      case QuestionType.singleChoice:
        return 'single_choice';
      case QuestionType.freeText:
        return 'free_text';
      case QuestionType.memberChoice:
        return 'member_choice';
      case QuestionType.duoChoice:
        return 'duo_choice';
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case QuestionType.binaryVote:
        return 'Yes/No Vote';
      case QuestionType.singleChoice:
        return 'Single Choice';
      case QuestionType.freeText:
        return 'Free Text';
      case QuestionType.memberChoice:
        return 'Vote for Member';
      case QuestionType.duoChoice:
        return 'Vote for Pair';
    }
  }

  /// Create QuestionType from API string
  static QuestionType fromString(String value) {
    switch (value) {
      case 'binary_vote':
        return QuestionType.binaryVote;
      case 'single_choice':
        return QuestionType.singleChoice;
      case 'free_text':
        return QuestionType.freeText;
      case 'member_choice':
        return QuestionType.memberChoice;
      case 'duo_choice':
        return QuestionType.duoChoice;
      default:
        return QuestionType.binaryVote;
    }
  }
}
