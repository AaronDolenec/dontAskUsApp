import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/group_websocket_service.dart';
import 'auth_provider.dart';
import 'group_provider.dart';
import 'question_provider.dart';

/// Connection state for the group-level WebSocket.
enum GroupWsConnectionState {
  disconnected,
  connecting,
  connected,
  authFailed,
  error,
}

/// State exposed by [groupWebSocketProvider].
class GroupWsState {
  final GroupWsConnectionState connectionState;
  final int onlineCount;
  final String? errorMessage;

  const GroupWsState({
    this.connectionState = GroupWsConnectionState.disconnected,
    this.onlineCount = 0,
    this.errorMessage,
  });

  GroupWsState copyWith({
    GroupWsConnectionState? connectionState,
    int? onlineCount,
    String? errorMessage,
  }) {
    return GroupWsState(
      connectionState: connectionState ?? this.connectionState,
      onlineCount: onlineCount ?? this.onlineCount,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for the group-level WebSocket.
final groupWebSocketProvider =
    StateNotifierProvider<GroupWsNotifier, GroupWsState>((ref) {
  return GroupWsNotifier(ref);
});

/// Manages a single [GroupWebSocketService] connection and dispatches
/// incoming events to the relevant Riverpod providers.
class GroupWsNotifier extends StateNotifier<GroupWsState> {
  final Ref _ref;
  GroupWebSocketService? _service;
  String? _connectedGroupId;

  GroupWsNotifier(this._ref) : super(const GroupWsState());

  /// Connect to the group WebSocket for [groupId].
  /// Disconnects any previous connection first.
  void connect(String groupId) {
    // Already connected to this group
    if (_connectedGroupId == groupId &&
        state.connectionState == GroupWsConnectionState.connected) {
      return;
    }

    disconnect();
    _connectedGroupId = groupId;

    state = state.copyWith(
      connectionState: GroupWsConnectionState.connecting,
    );

    _service = GroupWebSocketService(
      groupId: groupId,
      tokenProvider: () {
        // Synchronously return cached token — the WS service calls this
        // right before opening the connection.
        // We stash the latest token via the async helper below.
        return _cachedToken ?? '';
      },
      onEvent: _handleEvent,
      onConnected: () {
        if (!mounted) return;
        state = state.copyWith(
          connectionState: GroupWsConnectionState.connected,
        );
      },
      onDisconnected: (closeCode, reason) {
        if (!mounted) return;
        if (closeCode == 4001) {
          state = state.copyWith(
            connectionState: GroupWsConnectionState.authFailed,
            errorMessage: 'Authentication failed — please re-login',
          );
        } else {
          state = state.copyWith(
            connectionState: GroupWsConnectionState.disconnected,
          );
        }
      },
      onError: (error) {
        if (!mounted) return;
        state = state.copyWith(
          connectionState: GroupWsConnectionState.error,
          errorMessage: error.toString(),
        );
      },
    );

    // Fetch token then connect
    _fetchTokenAndConnect(groupId);
  }

  String? _cachedToken;

  Future<void> _fetchTokenAndConnect(String groupId) async {
    _cachedToken = await AuthService.getAccessToken();
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      state = state.copyWith(
        connectionState: GroupWsConnectionState.authFailed,
        errorMessage: 'No access token',
      );
      return;
    }
    _service?.connect();
  }

  /// Central event dispatcher.
  void _handleEvent(GroupWsEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case GroupWsEventType.voteUpdate:
        _handleVoteUpdate(event);
      case GroupWsEventType.newQuestion:
        _handleNewQuestion(event);
      case GroupWsEventType.streakUpdate:
        _handleStreakUpdate(event);
      case GroupWsEventType.memberJoined:
        _handleMemberJoined(event);
      case GroupWsEventType.memberLeft:
        _handleMemberLeft(event);
      case GroupWsEventType.pong:
        _handlePong(event);
      case GroupWsEventType.unknown:
        debugPrint('GroupWS: Unknown event type');
    }
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  void _handleVoteUpdate(GroupWsEvent event) {
    final data = event.data;
    final optionCounts = data['option_counts'] != null
        ? Map<String, int>.from(data['option_counts'] as Map)
        : <String, int>{};
    final totalVotes = data['total_votes'] as int? ?? 0;

    // Parse answer_details if present
    List<AnswerDetail>? answerDetails;
    if (data['answer_details'] != null) {
      answerDetails = (data['answer_details'] as List)
          .map((e) => AnswerDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Update the question provider
    _ref.read(questionProvider.notifier).updateVoteCounts(
          optionCounts,
          totalVotes,
          answerDetails: answerDetails,
        );
  }

  void _handleNewQuestion(GroupWsEvent event) {
    debugPrint('GroupWS: New question received — refreshing');
    // Re-fetch today's question from the API to get the full object
    _ref
        .read(questionProvider.notifier)
        .fetchTodaysQuestion(forceRefresh: true);
  }

  void _handleStreakUpdate(GroupWsEvent event) {
    final data = event.data;

    // Single-user streak after a vote
    if (data.containsKey('current_streak') &&
        data.containsKey('display_name')) {
      final displayName = data['display_name'] as String?;
      final currentStreak = data['current_streak'] as int? ?? 0;
      final longestStreak = data['longest_streak'] as int? ?? 0;

      // If this is the current user, update auth provider streak
      final authState = _ref.read(authProvider);
      if (authState.user?.displayName == displayName) {
        _ref.read(authProvider.notifier).updateStreak(
              currentStreak,
              longestStreak,
            );
      }
    }

    // Rollover streak update (all members) — invalidate leaderboard/members
    if (data.containsKey('reason') && data['reason'] == 'question_rollover') {
      _ref.invalidate(groupMembersProvider);
    }
  }

  void _handleMemberJoined(GroupWsEvent event) {
    debugPrint('GroupWS: Member joined — refreshing members');
    _ref.invalidate(groupMembersProvider);
  }

  void _handleMemberLeft(GroupWsEvent event) {
    debugPrint('GroupWS: Member left — refreshing members');
    _ref.invalidate(groupMembersProvider);
  }

  void _handlePong(GroupWsEvent event) {
    final onlineCount = event.data['online_count'] as int? ?? 0;
    state = state.copyWith(onlineCount: onlineCount);
  }

  // ---------------------------------------------------------------------------

  /// Disconnect the WebSocket.
  void disconnect() {
    _service?.dispose();
    _service = null;
    _connectedGroupId = null;
    _cachedToken = null;
    if (mounted) {
      state = const GroupWsState();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Whether the group WebSocket is connected.
final isGroupWsConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(groupWebSocketProvider);
  return state.connectionState == GroupWsConnectionState.connected;
});

/// Number of online members (from pong responses).
final onlineMembersCountProvider = Provider<int>((ref) {
  return ref.watch(groupWebSocketProvider).onlineCount;
});
