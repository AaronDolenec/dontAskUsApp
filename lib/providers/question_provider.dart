import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'api_provider.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

/// State for today's question
class QuestionState {
  final DailyQuestion? question;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;

  /// Whether the question is from today (true) or a previous day (false).
  /// When false, the question is shown in results-only mode.
  final bool isFromToday;

  const QuestionState({
    this.question,
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.isFromToday = true,
  });

  QuestionState copyWith({
    DailyQuestion? question,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
    bool? isFromToday,
  }) {
    return QuestionState(
      question: question ?? this.question,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFromToday: isFromToday ?? this.isFromToday,
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
  Timer? _pollTimer;
  String? _connectedQuestionId;

  QuestionNotifier(this._ref) : super(const QuestionState()) {
    // Watch auth state and fetch question when authenticated
    _ref.listen(authProvider, (previous, next) {
      if (next.hasGroup && !next.isLoading) {
        fetchTodaysQuestion();
        startPolling();
      }
    });

    // Initial fetch if already in a group
    final auth = _ref.read(authProvider);
    if (auth.hasGroup) {
      fetchTodaysQuestion();
    }
  }

  /// Start periodic polling for question updates
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      if (mounted) {
        _fetchFromApi(silent: true);
      }
    });
  }

  /// Stop periodic polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Check whether a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  /// Fetch today's question
  Future<void> fetchTodaysQuestion({bool forceRefresh = false}) async {
    final auth = _ref.read(authProvider);
    if (!auth.hasGroup) return;

    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await CacheService.getCachedQuestion(auth.groupId!);
      if (cached != null) {
        final isTodaysCached = _isToday(cached.questionDate);
        // Show cached question immediately (even if from a previous day)
        state = state.copyWith(
          question: cached,
          isLoading: false,
          isFromToday: isTodaysCached,
        );
        // Always refresh from API in background
        _fetchFromApi(silent: true);
        return;
      }
    }

    // No cache – show loading and fetch
    state = state.copyWith(isLoading: true);
    await _fetchFromApi();
  }

  Future<void> _fetchFromApi({bool silent = false}) async {
    final auth = _ref.read(authProvider);
    if (!auth.hasGroup) return;

    try {
      final token = await AuthService.getToken(auth.groupId!);
      if (token == null) {
        if (!silent) {
          state = state.copyWith(
            isLoading: false,
            error: 'Session expired',
          );
        }
        return;
      }

      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/groups/${auth.groupId}/questions/today',
        accessToken: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final question = DailyQuestion.fromJson(data);

        // Cache the question
        await CacheService.cacheQuestion(auth.groupId!, question);

        final oldQuestionId = state.question?.questionId;
        state = state.copyWith(
          question: question,
          isLoading: false,
          isFromToday: true,
        );

        // Auto-reconnect WebSocket if question changed
        if (question.questionId != oldQuestionId ||
            _connectedQuestionId != question.questionId) {
          connectWebSocket();
        }
      } else if (response.statusCode == 404) {
        // No question for today – show last question from cache if available
        if (state.question == null) {
          final cached = await CacheService.getCachedQuestion(auth.groupId!);
          if (cached != null) {
            state = state.copyWith(
              question: cached,
              isLoading: false,
              isFromToday: false,
            );
          } else {
            state = state.copyWith(isLoading: false, isFromToday: false);
          }
        } else {
          // Keep existing question but mark as not today's
          state = state.copyWith(
            isLoading: false,
            isFromToday: _isToday(state.question!.questionDate),
          );
        }
      } else {
        if (!silent) {
          final exception = ApiException.fromResponse(response);
          state = state.copyWith(
            isLoading: false,
            error: exception.userFriendlyMessage,
          );
        }
      }
    } catch (e) {
      if (!silent) {
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
  }

  /// Submit an answer/vote
  Future<bool> submitAnswer(dynamic answer, {String? textAnswer}) async {
    final auth = _ref.read(authProvider);
    final question = state.question;

    if (!auth.hasGroup || question == null) return false;

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
        accessToken: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answerResponse = AnswerResponse.fromJson(data);

        // Update question with new vote counts and answer details
        final updatedQuestion = question.copyWith(
          optionCounts: answerResponse.optionCounts,
          totalVotes: answerResponse.totalVotes,
          userVote: answerResponse.userAnswer,
          userTextAnswer: textAnswer,
          userStreak: answerResponse.currentStreak,
          longestStreak: answerResponse.longestStreak,
          answerDetails: answerResponse.answerDetails,
          textAnswers: answerResponse.textAnswers,
          featuredMember: answerResponse.featuredMember,
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

        // Trigger a background refresh to get the absolute latest state
        // (e.g. if other members voted between our fetch and submit)
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _fetchFromApi(silent: true);
        });

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

    // Don't reconnect if already connected to same question
    if (_connectedQuestionId == question.questionId && _wsService != null) {
      return;
    }

    _wsService?.dispose();
    _connectedQuestionId = question.questionId;
    debugPrint(
        'DEBUG: Connecting WebSocket for question ${question.questionId}');
    _wsService = WebSocketService(
      groupId: auth.groupId!,
      questionId: question.questionId,
      onVoteUpdate: (optionCounts, totalVotes, {answerDetails}) {
        if (!mounted) return;
        updateVoteCounts(optionCounts, totalVotes,
            answerDetails: answerDetails);
      },
      onError: (error) {
        if (!mounted) return;
        debugPrint('DEBUG: WebSocket error: $error');
      },
      onConnected: () {
        if (!mounted) return;
        debugPrint(
            'DEBUG: WebSocket connected for question ${question.questionId}');
      },
      onDisconnected: () {
        if (!mounted) return;
        debugPrint('DEBUG: WebSocket disconnected');
        _connectedQuestionId = null;
      },
    );
    try {
      _wsService!.connect();
    } catch (e) {
      debugPrint('DEBUG: WebSocket connect failed: $e');
    }
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    _wsService?.dispose();
    _wsService = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    disconnectWebSocket();
    super.dispose();
  }

  /// Update vote counts from WebSocket
  void updateVoteCounts(Map<String, int> optionCounts, int totalVotes,
      {List<AnswerDetail>? answerDetails}) {
    if (state.question == null) return;

    state = state.copyWith(
      question: state.question!.copyWith(
        optionCounts: optionCounts,
        totalVotes: totalVotes,
        answerDetails: answerDetails ?? state.question!.answerDetails,
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

  // Best source: today's question response includes user_streak
  final fromQuestion = questionState.question?.userStreak;
  if (fromQuestion != null && fromQuestion > 0) return fromQuestion;

  // Fallback: find current user in group members list
  final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
  if (members.isNotEmpty && authState.user != null) {
    final displayName = authState.user!.displayName;
    final me = members.cast<GroupMember?>().firstWhere(
          (m) => m!.displayName == displayName,
          orElse: () => null,
        );
    if (me != null && me.answerStreak > 0) return me.answerStreak;
  }

  return authState.user?.answerStreak ?? 0;
});

/// Provider for longest streak
final longestStreakProvider = Provider<int?>((ref) {
  final questionState = ref.watch(questionProvider);
  final authState = ref.watch(authProvider);

  // Best source: today's question
  final fromQuestion = questionState.question?.longestStreak;
  if (fromQuestion != null && fromQuestion > 0) return fromQuestion;

  // Fallback: group members
  final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
  if (members.isNotEmpty && authState.user != null) {
    final displayName = authState.user!.displayName;
    final me = members.cast<GroupMember?>().firstWhere(
          (m) => m!.displayName == displayName,
          orElse: () => null,
        );
    if (me != null) return me.longestAnswerStreak;
  }

  return authState.user?.longestAnswerStreak;
});
