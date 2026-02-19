import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/answer_detail.dart';
import 'api_config.dart';

/// WebSocket service for real-time vote updates
class WebSocketService {
  /// Public stream getter for listening to WebSocket messages (broadcast)
  Stream<dynamic> get stream => _broadcast ?? const Stream.empty();
  Stream<dynamic>? _broadcast;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  final String groupId;
  final String questionId;
  final Function(Map<String, int> optionCounts, int totalVotes,
      {List<AnswerDetail>? answerDetails})? onVoteUpdate;
  final Function()? onConnected;
  final Function(dynamic error)? onError;
  final Function()? onDisconnected;

  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  WebSocketService({
    required this.groupId,
    required this.questionId,
    this.onVoteUpdate,
    this.onConnected,
    this.onError,
    this.onDisconnected,
  });

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Connect to the WebSocket
  void connect() {
    if (_isConnected) return;

    try {
      final wsUrl =
          '${ApiConfig.wsBaseUrl}/ws/groups/$groupId/questions/$questionId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Create a single broadcast stream instance and listen to it. This
      // avoids "Stream has already been listened to" errors when multiple
      // parts of the app subscribe to updates.
      _broadcast = _channel!.stream.asBroadcastStream();
      _subscription = _broadcast!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      onConnected?.call();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'vote_update') {
        final optionCounts =
            Map<String, int>.from(data['option_counts'] as Map);
        final totalVotes = data['total_votes'] as int? ?? 0;

        // Parse answer_details if present in the WebSocket message
        List<AnswerDetail>? answerDetails;
        if (data['answer_details'] != null) {
          answerDetails = (data['answer_details'] as List)
              .map((e) => AnswerDetail.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        onVoteUpdate?.call(optionCounts, totalVotes,
            answerDetails: answerDetails);
      }
    } catch (e) {
      onError?.call('Failed to parse message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _isConnected = false;
    onError?.call(error);
    _attemptReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDone() {
    _isConnected = false;
    onDisconnected?.call();
    _attemptReconnect();
  }

  /// Attempt to reconnect
  void _attemptReconnect() {
    if (!_shouldReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      _reconnectDelay * (_reconnectAttempts + 1),
      () {
        _reconnectAttempts++;
        connect();
      },
    );
  }

  /// Send a vote via WebSocket
  void sendVote(String token, dynamic answer) {
    if (!_isConnected || _channel == null) {
      onError?.call('Not connected to WebSocket');
      return;
    }

    try {
      final message = jsonEncode({
        'type': 'vote',
        'token': token,
        'answer': answer,
      });
      _channel!.sink.add(message);
    } catch (e) {
      onError?.call('Failed to send vote: $e');
    }
  }

  /// Disconnect from the WebSocket
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _broadcast = null;
    _channel?.sink.close();
    _isConnected = false;
  }

  /// Dispose the service
  void dispose() {
    disconnect();
  }
}
