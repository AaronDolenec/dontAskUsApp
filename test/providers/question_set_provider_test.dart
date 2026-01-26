import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:dont_ask_us/providers/providers.dart';
import 'package:dont_ask_us/models/question_set.dart';
import '../mocks/fake_api_client.dart';

void main() {
  group('QuestionSet providers', () {
    test('publicQuestionSetsProvider returns list of sets', () async {
      final fake = FakeApiClient(
          onGet: (endpoint, {sessionToken, adminToken, queryParams}) async {
        return http.Response(
            '{"sets":[{"set_id":"s1","name":"Set 1","is_public":true,"created_at":"2025-01-01T00:00:00Z"}]}',
            200);
      });

      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(fake),
        // Ensure admin token is available for provider
        adminTokenProvider.overrideWith((ref) => Future.value('admintoken')),
      ]);

      final sets = await container.read(publicQuestionSetsProvider.future);
      expect(sets, isA<List<QuestionSet>>());
      expect(sets.length, 1);
      expect(sets.first.setId, 's1');
    });

    test('questionSetDetailsProvider returns set details', () async {
      final fake = FakeApiClient(
          onGet: (endpoint, {sessionToken, adminToken, queryParams}) async {
        return http.Response(
            '{"set_id":"s1","name":"Set 1","is_public":true,"created_at":"2025-01-01T00:00:00Z"}',
            200);
      });

      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(fake),
        adminTokenProvider.overrideWith((ref) => Future.value('admintoken')),
      ]);
      final set = await container.read(questionSetDetailsProvider('s1').future);
      expect(set, isNotNull);
      expect(set!.setId, 's1');
    });

    test('adminToken override works', () async {
      final container = ProviderContainer(overrides: [
        adminTokenProvider.overrideWith((ref) => Future.value('admintoken')),
      ]);

      final token = await container.read(adminTokenProvider.future);
      expect(token, 'admintoken');
    });

    test('createQuestionSetProvider creates set', () async {
      final fake = FakeApiClient(
          onPost: (endpoint, body, {sessionToken, adminToken}) async {
        // adminToken may be null in tests; ensure the provider handles it
        return http.Response(
            '{"set_id":"new","name":"New Set","is_public":true,"created_at":"2025-01-01T00:00:00Z"}',
            200);
      });

      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(fake),
        // Ensure admin token is available so the provider doesn't block
        adminTokenProvider.overrideWith((ref) => Future.value('admintoken')),
      ]);

      final result = await container
          .read(createQuestionSetProvider({'name': 'New Set'}).future);
      expect(result, isNotNull);
      expect(result!.setId, 'new');
    });

    test('assignQuestionSetsProvider posts assignment and returns true',
        () async {
      final fake = FakeApiClient(
          onPost: (endpoint, body, {sessionToken, adminToken}) async {
        expect(body['question_set_ids'][0], 's1');
        return http.Response('', 200);
      });

      final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(fake)]);
      final success = await container.read(assignQuestionSetsProvider({
        'groupId': 'g1',
        'adminToken': 'adm',
        'setIds': ['s1']
      }).future);
      expect(success, true);
    });

    test('groupQuestionSetsProvider returns group sets', () async {
      final fake = FakeApiClient(
          onGet: (endpoint, {sessionToken, adminToken, queryParams}) async {
        return http.Response(
            '{"question_sets":[{"set_id":"g1","name":"Group Set","is_public":false,"created_at":"2025-01-01T00:00:00Z"}]}',
            200);
      });

      final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(fake)]);
      final sets = await container.read(groupQuestionSetsProvider('g1').future);
      expect(sets.length, 1);
      expect(sets.first.setId, 'g1');
    });
  });
}
