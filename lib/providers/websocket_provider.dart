import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

/// State for WebSocket connection
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// WebSocket state holder
class WebSocketState {
  final WebSocketConnectionState connectionState;
  final String? errorMessage;
  final Map<String, int>? latestResults;
  final int totalVotes;

  const WebSocketState({
    this.connectionState = WebSocketConnectionState.disconnected,
    this.errorMessage,
    this.latestResults,
    this.totalVotes = 0,
  });

  WebSocketState copyWith({
    WebSocketConnectionState? connectionState,
    String? errorMessage,
    Map<String, int>? latestResults,
    int? totalVotes,
  }) {
    return WebSocketState(
      connectionState: connectionState ?? this.connectionState,
      errorMessage: errorMessage,
      latestResults: latestResults ?? this.latestResults,
      totalVotes: totalVotes ?? this.totalVotes,
    );
  }
}

/// WebSocket notifier for managing real-time connections
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  WebSocketService? _service;

  WebSocketNotifier() : super(const WebSocketState());

  /// Connect to WebSocket for a specific question
  void connect({
    required String groupId,
    required String questionId,
  }) {
    // Disconnect existing connection
    disconnect();

    state = state.copyWith(
      connectionState: WebSocketConnectionState.connecting,
    );

    _service = WebSocketService(
      groupId: groupId,
      questionId: questionId,
      onConnected: _onConnected,
      onDisconnected: _onDisconnected,
      onError: _onError,
      onVoteUpdate: (optionCounts, totalVotes, {answerDetails}) {
        _onVoteUpdate(optionCounts, totalVotes);
      },
    );

    _service!.connect();
  }

  void _onConnected() {
    state = state.copyWith(
      connectionState: WebSocketConnectionState.connected,
    );
  }

  void _onDisconnected() {
    state = state.copyWith(
      connectionState: WebSocketConnectionState.disconnected,
    );
  }

  void _onError(dynamic error) {
    state = state.copyWith(
      connectionState: WebSocketConnectionState.error,
      errorMessage: error.toString(),
    );
  }

  void _onVoteUpdate(Map<String, int> optionCounts, int totalVotes) {
    state = state.copyWith(
      latestResults: optionCounts,
      totalVotes: totalVotes,
    );
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _service?.disconnect();
    _service = null;
    state = const WebSocketState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Provider for WebSocket state
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  return WebSocketNotifier();
});

/// Provider to check if WebSocket is connected
final isWebSocketConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(webSocketProvider);
  return state.connectionState == WebSocketConnectionState.connected;
});

/// Provider for latest vote results from WebSocket
final liveVoteResultsProvider = Provider<Map<String, int>?>((ref) {
  final state = ref.watch(webSocketProvider);
  return state.latestResults;
});
