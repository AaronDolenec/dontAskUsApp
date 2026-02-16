import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../services/api_client.dart';
import 'dart:convert';
import 'api_provider.dart';

final privateSetProvider =
    StateNotifierProvider<PrivateSetNotifier, PrivateSetState>((ref) {
  return PrivateSetNotifier(ref);
});

class PrivateSetState {
  final List<dynamic> sets;
  final Map<String, dynamic>? currentSet;
  final String? message;
  PrivateSetState({
    this.sets = const [],
    this.currentSet,
    this.message,
  });

  PrivateSetState copyWith({
    List<dynamic>? sets,
    Map<String, dynamic>? currentSet,
    String? message,
  }) {
    return PrivateSetState(
      sets: sets ?? this.sets,
      currentSet: currentSet ?? this.currentSet,
      message: message ?? this.message,
    );
  }
}

class PrivateSetNotifier extends StateNotifier<PrivateSetState> {
  final Ref ref;
  PrivateSetNotifier(this.ref) : super(PrivateSetState());

  Future<void> createPrivateSet(
      String groupId, String accessToken, Map<String, dynamic> setData) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post(
        '/api/groups/$groupId/question-sets/private', setData,
        accessToken: accessToken);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(message: data['message']);
    }
  }

  Future<void> listMyPrivateSets(String groupId, String accessToken,
      {int limit = 50, int offset = 0}) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
        '/api/groups/$groupId/question-sets/my?limit=$limit&offset=$offset',
        accessToken: accessToken);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(sets: data['sets']);
    }
  }

  Future<void> getSetDetails(
      String groupId, String setId, String accessToken) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/$groupId/question-sets/$setId',
        accessToken: accessToken);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(currentSet: data);
    }
  }

  Future<void> updatePrivateSet(String groupId, String setId,
      String accessToken, Map<String, dynamic> setData) async {
    final api = ref.read(apiClientProvider);
    final response = await api.put(
        '/api/groups/$groupId/question-sets/$setId', setData,
        accessToken: accessToken);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(message: data['message']);
    }
  }

  Future<void> deletePrivateSet(
      String groupId, String setId, String accessToken) async {
    final api = ref.read(apiClientProvider);
    final response = await api.delete(
        '/api/groups/$groupId/question-sets/$setId',
        accessToken: accessToken);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(message: data['message']);
    }
  }

  Future<void> getSetUsage(
      String groupId, String setId, String accessToken) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
        '/api/groups/$groupId/question-sets/$setId/usage',
        accessToken: accessToken);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(currentSet: data);
    }
  }
}
