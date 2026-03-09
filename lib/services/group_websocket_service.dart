import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

/// Event types received from the group-level WebSocket.
enum GroupWsEventType {
  voteUpdate,
  newQuestion,
  streakUpdate,
  memberJoined,
  memberLeft,
  pong,
  unknown,
}

/// Parsed WebSocket event from the group-level connection.
class GroupWsEvent {
  final GroupWsEventType type;
  final DateTime? timestamp;
  final Map<String, dynamic> data;

  const GroupWsEvent({
    required this.type,
    this.timestamp,
    required this.data,
  });

  factory GroupWsEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final type = switch (typeStr) {
      'vote_update' => GroupWsEventType.voteUpdate,
      'new_question' => GroupWsEventType.newQuestion,
      'streak_update' => GroupWsEventType.streakUpdate,
      'member_joined' => GroupWsEventType.memberJoined,
      'member_left' => GroupWsEventType.memberLeft,
      'pong' => GroupWsEventType.pong,
      _ => GroupWsEventType.unknown,
    };

    DateTime? timestamp;
    if (json['timestamp'] != null) {
      timestamp = DateTime.tryParse(json['timestamp'] as String);
    }

    // The data payload may be nested under "data" or at the top level
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return GroupWsEvent(type: type, timestamp: timestamp, data: data);
  }
}

/// Group-level WebSocket service.
///
/// Connects to `WS /ws/groups/{group_id}?token=<jwt>` and receives all
/// real-time events: vote_update, new_question, streak_update,
/// member_joined, member_left.
///
/// Implements keepalive pings every 30 s and exponential-backoff reconnection.
class GroupWebSocketService {
  final String groupId;
  final String Function() tokenProvider;

  // Callbacks for each event type
  final void Function(GroupWsEvent event)? onEvent;
  final void Function()? onConnected;
  final void Function(int? closeCode, String? reason)? onDisconnected;
  final void Function(dynamic error)? onError;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _pongTimeout = Duration(seconds: 10);
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  GroupWebSocketService({
    required this.groupId,
    required this.tokenProvider,
    this.onEvent,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  bool get isConnected => _isConnected;

  /// Connect to the group-level WebSocket.
  void connect() {
    if (_isConnected) return;
    _shouldReconnect = true;

    try {
      final token = tokenProvider();
      if (token.isEmpty) {
        onError?.call('No access token available');
        return;
      }

      final wsUrl = '${ApiConfig.wsBaseUrl}/ws/groups/$groupId?token=$token';
      debugPrint('GroupWS: Connecting to $groupId');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // On web, the ready future rejects when the connection is refused.
      // Catch it so the error flows through _handleError instead of being
      // an uncaught Future rejection.
      _channel!.ready.then((_) {
        if (!_isConnected) {
          _isConnected = true;
          _reconnectAttempts = 0;
          _startPingTimer();
          onConnected?.call();
          debugPrint('GroupWS: Connected');
        }
      }).catchError((Object e) {
        debugPrint('GroupWS: Connection refused: $e');
        _handleError(e);
      });
    } catch (e) {
      debugPrint('GroupWS: Connection failed: $e');
      _handleError(e);
    }
  }

  /// Handle incoming messages.
  void _handleMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = GroupWsEvent.fromJson(json);

      if (event.type == GroupWsEventType.pong) {
        _pongTimeoutTimer?.cancel();
      }

      onEvent?.call(event);
    } catch (e) {
      debugPrint('GroupWS: Failed to parse message: $e');
      onError?.call('Failed to parse message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('GroupWS: Error: $error');
    _isConnected = false;
    _stopPingTimer();
    onError?.call(error);
    _attemptReconnect();
  }

  void _handleDone() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    debugPrint('GroupWS: Disconnected (code=$closeCode, reason=$closeReason)');
    _isConnected = false;
    _stopPingTimer();
    onDisconnected?.call(closeCode, closeReason);

    // Auth failure — don't reconnect with same token
    if (closeCode == 4001) {
      debugPrint('GroupWS: Auth failed, not reconnecting');
      return;
    }

    _attemptReconnect();
  }

  /// Send keepalive ping.
  void _sendPing() {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
      // Start pong timeout
      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = Timer(_pongTimeout, () {
        debugPrint('GroupWS: Pong timeout — reconnecting');
        _forceReconnect();
      });
    } catch (e) {
      debugPrint('GroupWS: Failed to send ping: $e');
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  /// Force-close and reconnect.
  void _forceReconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _stopPingTimer();
    _attemptReconnect();
  }

  /// Exponential backoff reconnection.
  void _attemptReconnect() {
    if (!_shouldReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('GroupWS: Max reconnection attempts reached');
      onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts);
    final clampedDelay =
        delay > _maxReconnectDelay ? _maxReconnectDelay : delay;

    debugPrint(
        'GroupWS: Reconnecting in ${clampedDelay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(clampedDelay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  /// Disconnect and stop reconnection.
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopPingTimer();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    debugPrint('GroupWS: Disconnected (manual)');
  }

  /// Alias for [disconnect].
  void dispose() => disconnect();
}
