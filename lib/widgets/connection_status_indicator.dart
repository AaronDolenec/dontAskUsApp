import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/utils.dart';

/// Widget that shows the current connection status
class ConnectionStatusIndicator extends ConsumerWidget {
  final bool showWhenConnected;

  const ConnectionStatusIndicator({
    super.key,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(connectivityProvider);
    final wsState = ref.watch(webSocketProvider);

    // Don't show anything when connected (unless showWhenConnected is true)
    if (networkState == NetworkState.online &&
        wsState.connectionState == WebSocketConnectionState.connected &&
        !showWhenConnected) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(networkState, wsState.connectionState),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(networkState, wsState.connectionState),
          const SizedBox(width: 6),
          Text(
            _getStatusText(networkState, wsState.connectionState),
            style: TextStyle(
              color: _getTextColor(networkState, wsState.connectionState),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(
    NetworkState networkState,
    WebSocketConnectionState wsState,
  ) {
    if (networkState == NetworkState.offline) {
      return const Icon(
        Icons.wifi_off,
        size: 14,
        color: Colors.white,
      );
    }

    switch (wsState) {
      case WebSocketConnectionState.connecting:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
      case WebSocketConnectionState.connected:
        return const Icon(
          Icons.wifi,
          size: 14,
          color: Colors.white,
        );
      case WebSocketConnectionState.error:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.white,
        );
      case WebSocketConnectionState.disconnected:
        return const Icon(
          Icons.sync_disabled,
          size: 14,
          color: Colors.white,
        );
    }
  }

  Color _getBackgroundColor(
    NetworkState networkState,
    WebSocketConnectionState wsState,
  ) {
    if (networkState == NetworkState.offline) {
      return AppColors.error;
    }

    switch (wsState) {
      case WebSocketConnectionState.connecting:
        return AppColors.warning;
      case WebSocketConnectionState.connected:
        return AppColors.success;
      case WebSocketConnectionState.error:
        return AppColors.error;
      case WebSocketConnectionState.disconnected:
        return AppColors.secondary;
    }
  }

  Color _getTextColor(
    NetworkState networkState,
    WebSocketConnectionState wsState,
  ) {
    return Colors.white;
  }

  String _getStatusText(
    NetworkState networkState,
    WebSocketConnectionState wsState,
  ) {
    if (networkState == NetworkState.offline) {
      return 'Offline';
    }

    switch (wsState) {
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.connected:
        return 'Live';
      case WebSocketConnectionState.error:
        return 'Connection error';
      case WebSocketConnectionState.disconnected:
        return 'Disconnected';
    }
  }
}

/// Banner widget shown at top of screen when offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(connectivityProvider);

    if (networkState != NetworkState.offline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error,
      child: const SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'No internet connection',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
