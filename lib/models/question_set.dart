/// QuestionSet model for curated question collections
class QuestionSet {
  final String setId;
  final String name;
  final String? description;
  final bool isPublic;
  final int? templateCount;
  final DateTime createdAt;

  QuestionSet({
    required this.setId,
    required this.name,
    this.description,
    required this.isPublic,
    this.templateCount,
    required this.createdAt,
  });

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    return QuestionSet(
      setId: json['set_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      templateCount: json['template_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'name': name,
      'description': description,
      'is_public': isPublic,
      'template_count': templateCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  QuestionSet copyWith({
    String? setId,
    String? name,
    String? description,
    bool? isPublic,
    int? templateCount,
    DateTime? createdAt,
  }) {
    return QuestionSet(
      setId: setId ?? this.setId,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      templateCount: templateCount ?? this.templateCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'QuestionSet(name: $name, templates: $templateCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionSet && other.setId == setId;
  }

  @override
  int get hashCode => setId.hashCode;
}

/// QuestionTemplate model for individual question templates in a set
class QuestionTemplate {
  final int id;
  final String templateId;
  final String questionText;
  final String questionType;

  QuestionTemplate({
    required this.id,
    required this.templateId,
    required this.questionText,
    required this.questionType,
  });

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) {
    return QuestionTemplate(
      id: json['id'] as int,
      templateId: json['template_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'question_text': questionText,
      'question_type': questionType,
    };
  }
}
