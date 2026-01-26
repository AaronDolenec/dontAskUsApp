import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_set.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

/// Create a new public question set (admin)
final createQuestionSetProvider =
    FutureProvider.family<QuestionSet?, Map<String, dynamic>>(
        (ref, body) async {
  final api = ref.read(apiClientProvider);
  final adminToken = await ref.read(adminTokenProvider.future);
  final response =
      await api.post('/api/question-sets', body, adminToken: adminToken);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return QuestionSet.fromJson(data);
  }
  return null;
});
// ...existing code...

/// Provider for listing public question sets
final publicQuestionSetsProvider =
    FutureProvider<List<QuestionSet>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/question-sets');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final setsJson = data['sets'] as List? ?? [];
    return setsJson
        .map((s) => QuestionSet.fromJson(s as Map<String, dynamic>))
        .toList();
  }
  return [];
});

/// Provider for question set details
final questionSetDetailsProvider =
    FutureProvider.family<QuestionSet?, String>((ref, setId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/question-sets/$setId');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return QuestionSet.fromJson(data);
  }
  return null;
});

/// Provider for assigning question sets to a group (admin)
final assignQuestionSetsProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final api = ref.read(apiClientProvider);
  final groupId = params['groupId'] as String;
  final adminToken = params['adminToken'] as String;
  final setIds = params['setIds'] as List<String>;
  final replace = params['replace'] as bool? ?? false;
  final response = await api.post(
    '/api/groups/$groupId/question-sets',
    {'question_set_ids': setIds, 'replace': replace},
    adminToken: adminToken,
  );
  return response.statusCode == 200;
});

/// Provider for listing group question sets
final groupQuestionSetsProvider =
    FutureProvider.family<List<QuestionSet>, String>((ref, groupId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/groups/$groupId/question-sets');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final setsJson = data['question_sets'] as List? ?? [];
    return setsJson
        .map((s) => QuestionSet.fromJson(s as Map<String, dynamic>))
        .toList();
  }
  return [];
});
