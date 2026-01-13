import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'api_provider.dart';
import 'auth_provider.dart';
import '../services/websocket_service.dart';

/// State for today's question
class QuestionState {
  final DailyQuestion? question;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;

  const QuestionState({
    this.question,
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
  });

  QuestionState copyWith({
    DailyQuestion? question,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
  }) {
    return QuestionState(
      question: question ?? this.question,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Provider for today's question state
final questionProvider =
    StateNotifierProvider<QuestionNotifier, QuestionState>((ref) {
  return QuestionNotifier(ref);
});

/// Question state notifier
class QuestionNotifier extends StateNotifier<QuestionState> {
  final Ref _ref;
  WebSocketService? _wsService;

  QuestionNotifier(this._ref) : super(const QuestionState()) {
    // Watch auth state and fetch question when authenticated
    _ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isLoading) {
        fetchTodaysQuestion();
      }
    });

    // Initial fetch if already authenticated
    final auth = _ref.read(authProvider);
    if (auth.isAuthenticated) {
      fetchTodaysQuestion();
    }
  }

  /// Fetch today's question
  Future<void> fetchTodaysQuestion({bool forceRefresh = false}) async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    state = state.copyWith(isLoading: true);

    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await CacheService.getCachedQuestion(auth.groupId!);
      if (cached != null) {
        // Check if it's still today's question
        final now = DateTime.now();
        final questionDate = cached.questionDate;
        if (now.year == questionDate.year &&
            now.month == questionDate.month &&
            now.day == questionDate.day) {
          state = state.copyWith(question: cached, isLoading: false);
          // Still refresh in background
          _fetchFromApi();
          return;
        }
      }
    }

    await _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    try {
      final token = await AuthService.getToken(auth.groupId!);
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Session expired',
        );
        return;
      }

      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/groups/${auth.groupId}/questions/today',
        sessionToken: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final question = DailyQuestion.fromJson(data);

        // Cache the question
        await CacheService.cacheQuestion(auth.groupId!, question);

        state = state.copyWith(question: question, isLoading: false);
      } else if (response.statusCode == 404) {
        // No question for today
        state = state.copyWith(isLoading: false);
      } else {
        final exception = ApiException.fromResponse(response);
        state = state.copyWith(
          isLoading: false,
          error: exception.userFriendlyMessage,
        );
      }
    } catch (e) {
      // Try to use cached question
      final auth = _ref.read(authProvider);
      final cached = await CacheService.getCachedQuestion(auth.groupId!);

      state = state.copyWith(
        question: cached,
        isLoading: false,
        error: cached == null ? 'Failed to load question' : null,
      );
    }
  }

  /// Submit an answer/vote
  Future<bool> submitAnswer(dynamic answer, {String? textAnswer}) async {
    final auth = _ref.read(authProvider);
    final question = state.question;

    if (!auth.isAuthenticated || question == null) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      final token = await AuthService.getToken(auth.groupId!);
      if (token == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Session expired',
        );
        return false;
      }

      final api = _ref.read(apiClientProvider);
      final body = <String, dynamic>{};

      if (textAnswer != null) {
        body['text_answer'] = textAnswer;
      } else {
        body['answer'] = answer;
      }

      final response = await api.post(
        '/api/groups/${auth.groupId}/questions/${question.questionId}/answer',
        body,
        sessionToken: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answerResponse = AnswerResponse.fromJson(data);

        // Update question with new vote counts
        final updatedQuestion = question.copyWith(
          optionCounts: answerResponse.optionCounts,
          totalVotes: answerResponse.totalVotes,
          userVote: answerResponse.userAnswer,
          userTextAnswer: textAnswer,
          userStreak: answerResponse.currentStreak,
          longestStreak: answerResponse.longestStreak,
        );

        // Update cache
        await CacheService.cacheQuestion(auth.groupId!, updatedQuestion);

        // Update auth provider streak
        _ref.read(authProvider.notifier).updateStreak(
              answerResponse.currentStreak,
              answerResponse.longestStreak,
            );

        state = state.copyWith(
          question: updatedQuestion,
          isSubmitting: false,
        );
        return true;
      }

      final exception = ApiException.fromResponse(response);
      state = state.copyWith(
        isSubmitting: false,
        error: exception.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Connect to WebSocket for live updates
  void connectWebSocket() {
    final question = state.question;
    final auth = _ref.read(authProvider);
    if (question == null || auth.groupId == null) return;
    _wsService?.dispose();
    _wsService = WebSocketService(
      groupId: auth.groupId!,
      questionId: question.questionId,
      onVoteUpdate: (optionCounts, totalVotes) {
        updateVoteCounts(optionCounts, totalVotes);
      },
      onError: (error) {
        // Optionally handle error
      },
      onConnected: () {
        // Optionally handle connection
      },
      onDisconnected: () {
        // Optionally handle disconnect
      },
    );
    _wsService!.connect();
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    _wsService?.dispose();
    _wsService = null;
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }

  /// Update vote counts from WebSocket
  void updateVoteCounts(Map<String, int> optionCounts, int totalVotes) {
    if (state.question == null) return;

    state = state.copyWith(
      question: state.question!.copyWith(
        optionCounts: optionCounts,
        totalVotes: totalVotes,
      ),
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }
}

/// Provider for checking if user has voted today
final hasVotedTodayProvider = Provider<bool>((ref) {
  final questionState = ref.watch(questionProvider);
  return questionState.question?.hasUserVoted ?? false;
});

/// Provider for current user's streak
final userStreakProvider = Provider<int>((ref) {
  final questionState = ref.watch(questionProvider);
  final authState = ref.watch(authProvider);

  return questionState.question?.userStreak ??
      authState.user?.answerStreak ??
      0;
});
