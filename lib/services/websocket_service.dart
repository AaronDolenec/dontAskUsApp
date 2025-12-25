import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

/// WebSocket service for real-time vote updates
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  
  final String groupId;
  final String questionId;
  final Function(Map<String, int> optionCounts, int totalVotes)? onVoteUpdate;
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
      final wsUrl = '${ApiConfig.wsBaseUrl}/ws/groups/$groupId/questions/$questionId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _subscription = _channel!.stream.listen(
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
        final optionCounts = Map<String, int>.from(data['option_counts'] as Map);
        final totalVotes = data['total_votes'] as int? ?? 0;
        onVoteUpdate?.call(optionCounts, totalVotes);
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
  void sendVote(String sessionToken, dynamic answer) {
    if (!_isConnected || _channel == null) {
      onError?.call('Not connected to WebSocket');
      return;
    }
    
    try {
      final message = jsonEncode({
        'type': 'vote',
        'session_token': sessionToken,
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
    _channel?.sink.close();
    _isConnected = false;
  }

  /// Dispose the service
  void dispose() {
    disconnect();
  }
}
