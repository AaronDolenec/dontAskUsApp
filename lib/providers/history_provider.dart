import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

/// Provider for question history
final questionHistoryProvider =
    FutureProvider.family<List<DailyQuestion>, int>((ref, page) async {
  final auth = ref.watch(authProvider);
  if (!auth.hasGroup) return [];

  try {
    final token = await AuthService.getToken(auth.groupId!);
    if (token == null) return [];

    final api = ref.read(apiClientProvider);
    // Use skip/limit pagination as per API docs
    final skip = page * 20;
    final response = await api.get(
      '/api/groups/${auth.groupId}/questions/history',
      accessToken: token,
      queryParams: {
        'skip': skip.toString(),
        'limit': '20',
      },
    ).timeout(const Duration(seconds: 5), onTimeout: () {
      throw Exception('Request timed out. Please check your connection.');
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Handle both list and object response formats
      List questionsJson;
      if (data is List) {
        questionsJson = data;
      } else if (data is Map && data.containsKey('questions')) {
        questionsJson = data['questions'] as List;
      } else {
        return [];
      }

      return questionsJson
          .map((q) => DailyQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    // Just throw the error, let the caller handle it
    rethrow;
  }

  return [];
});

/// Provider for paginated history state
class HistoryState {
  final List<DailyQuestion> questions;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const HistoryState({
    this.questions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  HistoryState copyWith({
    List<DailyQuestion>? questions,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return HistoryState(
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

/// Provider for paginated history
final paginatedHistoryProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  WebSocketService? _wsService;

  HistoryNotifier(this._ref) : super(const HistoryState()) {
    _connectWebSocket();
  }

  /// Load initial history
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      questions: [],
      currentPage: 0,
    );
    await _loadPage(0);
  }

  /// Load next page
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    await _loadPage(state.currentPage + 1);
  }

  /// Refresh history
  Future<void> refresh() async {
    state = state.copyWith(
      questions: [],
      currentPage: 0,
      hasMore: true,
    );
    await loadInitial();
  }

  Future<void> _loadPage(int page) async {
    final auth = _ref.read(authProvider);
    if (!auth.hasGroup) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final token = await AuthService.getToken(auth.groupId!);
      if (token == null) {
        state = state.copyWith(isLoading: false, error: 'Session expired');
        return;
      }
      final api = _ref.read(apiClientProvider);
      final skip = page * 20;
      final response = await api.get(
        '/api/groups/${auth.groupId}/questions/history',
        accessToken: token,
        queryParams: {
          'skip': skip.toString(),
          'limit': '20',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List questionsJson;
        if (data is List) {
          questionsJson = data;
        } else if (data is Map && data.containsKey('questions')) {
          questionsJson = data['questions'] as List;
        } else {
          questionsJson = [];
        }
        final newQuestions = questionsJson
            .map((q) => DailyQuestion.fromJson(q as Map<String, dynamic>))
            .toList();
        final allQuestions =
            page == 0 ? newQuestions : [...state.questions, ...newQuestions];
        state = state.copyWith(
          questions: allQuestions,
          isLoading: false,
          hasMore: newQuestions.length >= 20,
          currentPage: page,
        );
      } else if (response.statusCode == 404) {
        state = state.copyWith(
          questions: [],
          isLoading: false,
          hasMore: false,
        );
      } else {
        final exception = ApiException.fromResponse(response);
        state = state.copyWith(
          isLoading: false,
          error: exception.userFriendlyMessage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        questions: [],
        isLoading: false,
        hasMore: false,
      );
    }
  }

  void _connectWebSocket() {
    final auth = _ref.read(authProvider);
    if (!auth.hasGroup || auth.groupId == null) return;
    _wsService?.dispose();
    _wsService = WebSocketService(
      groupId: auth.groupId!,
      questionId: '', // Not needed for history
      onConnected: () {},
      onError: (error) {},
      onDisconnected: () {},
    );
    _wsService!.connect();
    _wsService!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic> && data['type'] == 'history_update') {
        final questionsJson = data['questions'] as List? ?? [];
        final newQuestions = questionsJson
            .map((q) => DailyQuestion.fromJson(q as Map<String, dynamic>))
            .toList();
        // Prepend new questions to the history
        state =
            state.copyWith(questions: [...newQuestions, ...state.questions]);
      }
    });
  }

  @override
  void dispose() {
    _wsService?.dispose();
    super.dispose();
  }
}
