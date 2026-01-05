import 'package:flutter_test/flutter_test.dart';

import 'package:dont_ask_us/models/models.dart';

void main() {
  group('User Model', () {
    test('fromJson creates User correctly', () {
      final json = {
        'id': 1,
        'user_id': 'user123',
        'display_name': 'John Doe',
        'color_avatar': '#FF5733',
        'session_token': 'token123',
        'created_at': '2025-01-01T00:00:00Z',
        'answer_streak': 5,
        'longest_answer_streak': 10,
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.oderId, 'user123');
      expect(user.displayName, 'John Doe');
      expect(user.colorAvatar, '#FF5733');
      expect(user.sessionToken, 'token123');
      expect(user.answerStreak, 5);
      expect(user.longestAnswerStreak, 10);
    });

    test('toJson converts User correctly', () {
      final user = User(
        id: 1,
        oderId: 'user123',
        displayName: 'John Doe',
        colorAvatar: '#FF5733',
        sessionToken: 'token123',
        createdAt: DateTime.utc(2025),
        answerStreak: 5,
        longestAnswerStreak: 10,
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['user_id'], 'user123');
      expect(json['display_name'], 'John Doe');
      expect(json['color_avatar'], '#FF5733');
      expect(json['session_token'], 'token123');
      expect(json['answer_streak'], 5);
      expect(json['longest_answer_streak'], 10);
    });
  });

  group('Group Model', () {
    test('fromJson creates Group correctly', () {
      final json = {
        'id': 1,
        'group_id': 'group123',
        'name': 'Test Group',
        'invite_code': 'ABC123',
        'created_at': '2025-01-01T00:00:00Z',
        'member_count': 10,
      };

      final group = Group.fromJson(json);

      expect(group.id, 1);
      expect(group.groupId, 'group123');
      expect(group.name, 'Test Group');
      expect(group.inviteCode, 'ABC123');
      expect(group.memberCount, 10);
    });

    test('toJson converts Group correctly', () {
      final group = Group(
        id: 1,
        groupId: 'group123',
        name: 'Test Group',
        inviteCode: 'ABC123',
        createdAt: DateTime.utc(2025),
        memberCount: 10,
      );

      final json = group.toJson();

      expect(json['id'], 1);
      expect(json['group_id'], 'group123');
      expect(json['name'], 'Test Group');
      expect(json['invite_code'], 'ABC123');
      expect(json['member_count'], 10);
    });

    test('isAdmin returns correct value based on adminToken', () {
      final groupWithAdmin = Group(
        id: 1,
        groupId: 'group123',
        name: 'Test Group',
        inviteCode: 'ABC123',
        adminToken: 'adminToken123',
        createdAt: DateTime.utc(2025),
      );

      final groupWithoutAdmin = Group(
        id: 2,
        groupId: 'group456',
        name: 'Test Group 2',
        inviteCode: 'DEF456',
        createdAt: DateTime.utc(2025),
      );

      expect(groupWithAdmin.isAdmin, true);
      expect(groupWithoutAdmin.isAdmin, false);
    });
  });

  group('GroupMember Model', () {
    test('fromJson creates GroupMember correctly', () {
      final json = {
        'user_id': 'member123',
        'display_name': 'Jane Smith',
        'color_avatar': '#3366FF',
        'answer_streak': 3,
        'longest_answer_streak': 7,
      };

      final member = GroupMember.fromJson(json);

      expect(member.oderId, 'member123');
      expect(member.displayName, 'Jane Smith');
      expect(member.colorAvatar, '#3366FF');
      expect(member.answerStreak, 3);
      expect(member.longestAnswerStreak, 7);
    });

    test('initials returns correct value', () {
      final member = GroupMember(
        oderId: 'member123',
        displayName: 'Jane Smith',
        colorAvatar: '#3366FF',
      );

      expect(member.initials, 'JS');

      final singleName = GroupMember(
        oderId: 'member456',
        displayName: 'Bob',
        colorAvatar: '#3366FF',
      );

      expect(singleName.initials, 'BO');
    });
  });

  group('QuestionType', () {
    test('fromString parses question types correctly', () {
      expect(QuestionTypeExtension.fromString('binary_vote'),
          QuestionType.binaryVote);
      expect(QuestionTypeExtension.fromString('single_choice'),
          QuestionType.singleChoice);
      expect(
          QuestionTypeExtension.fromString('free_text'), QuestionType.freeText);
      expect(QuestionTypeExtension.fromString('member_choice'),
          QuestionType.memberChoice);
      expect(QuestionTypeExtension.fromString('duo_choice'),
          QuestionType.duoChoice);
    });

    test('apiValue converts to API format', () {
      expect(QuestionType.binaryVote.apiValue, 'binary_vote');
      expect(QuestionType.singleChoice.apiValue, 'single_choice');
      expect(QuestionType.freeText.apiValue, 'free_text');
      expect(QuestionType.memberChoice.apiValue, 'member_choice');
      expect(QuestionType.duoChoice.apiValue, 'duo_choice');
    });

    test('displayName returns friendly name', () {
      expect(QuestionType.binaryVote.displayName, 'Yes/No Vote');
      expect(QuestionType.singleChoice.displayName, 'Single Choice');
      expect(QuestionType.freeText.displayName, 'Free Text');
      expect(QuestionType.memberChoice.displayName, 'Vote for Member');
      expect(QuestionType.duoChoice.displayName, 'Vote for Pair');
    });
  });

  group('DailyQuestion Model', () {
    test('fromJson creates DailyQuestion correctly', () {
      final json = {
        'id': 1,
        'question_id': 'q123',
        'question_text': 'What is your favorite color?',
        'question_type': 'single_choice',
        'options': ['Red', 'Blue', 'Green'],
        'option_counts': {'Red': 5, 'Blue': 3, 'Green': 2},
        'question_date': '2025-01-01T00:00:00Z',
        'is_active': true,
        'total_votes': 10,
        'allow_multiple': false,
      };

      final question = DailyQuestion.fromJson(json);

      expect(question.id, 1);
      expect(question.questionId, 'q123');
      expect(question.questionText, 'What is your favorite color?');
      expect(question.questionType, QuestionType.singleChoice);
      expect(question.options, ['Red', 'Blue', 'Green']);
      expect(question.allowMultiple, false);
      expect(question.optionCounts?['Red'], 5);
      expect(question.totalVotes, 10);
    });

    test('fromJson handles binary vote', () {
      final json = {
        'id': 2,
        'question_id': 'q456',
        'question_text': 'Do you like pizza?',
        'question_type': 'binary_vote',
        'options': ['Yes', 'No'],
        'question_date': '2025-01-01T00:00:00Z',
        'is_active': true,
        'allow_multiple': false,
      };

      final question = DailyQuestion.fromJson(json);

      expect(question.questionType, QuestionType.binaryVote);
      expect(question.options, ['Yes', 'No']);
    });

    test('hasUserVoted returns correct value', () {
      final questionWithVote = DailyQuestion(
        id: 1,
        questionId: 'q123',
        questionText: 'Test?',
        questionType: QuestionType.binaryVote,
        questionDate: DateTime.now(),
        isActive: true,
        userVote: 'Yes',
      );

      final questionWithoutVote = DailyQuestion(
        id: 2,
        questionId: 'q456',
        questionText: 'Test 2?',
        questionType: QuestionType.binaryVote,
        questionDate: DateTime.now(),
        isActive: true,
      );

      expect(questionWithVote.hasUserVoted, true);
      expect(questionWithoutVote.hasUserVoted, false);
    });
  });

  group('AnswerResponse Model', () {
    test('fromJson creates AnswerResponse correctly', () {
      final json = {
        'message': 'Vote recorded successfully',
        'question_id': 'q123',
        'total_votes': 10,
        'current_streak': 5,
        'longest_streak': 10,
      };

      final response = AnswerResponse.fromJson(json);

      expect(response.message, 'Vote recorded successfully');
      expect(response.questionId, 'q123');
      expect(response.totalVotes, 10);
      expect(response.currentStreak, 5);
      expect(response.longestStreak, 10);
      expect(response.isSuccess, true);
    });
  });

  group('QuestionSet Model', () {
    test('fromJson creates QuestionSet correctly', () {
      final json = {
        'set_id': 'set123',
        'name': 'Fun Questions',
        'description': 'A collection of fun questions',
        'template_count': 10,
        'is_public': true,
        'created_at': '2025-01-01T00:00:00Z',
      };

      final set = QuestionSet.fromJson(json);

      expect(set.setId, 'set123');
      expect(set.name, 'Fun Questions');
      expect(set.description, 'A collection of fun questions');
      expect(set.templateCount, 10);
      expect(set.isPublic, true);
    });
  });
}
