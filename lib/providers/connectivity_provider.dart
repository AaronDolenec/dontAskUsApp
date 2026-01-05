import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity state
enum NetworkState {
  online,
  offline,
  unknown,
}

/// Connectivity notifier for monitoring network state
class ConnectivityNotifier extends StateNotifier<NetworkState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(NetworkState.unknown) {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateState(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = NetworkState.offline;
    } else {
      state = NetworkState.online;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for network connectivity state
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkState>((ref) {
  return ConnectivityNotifier();
});

/// Provider to check if online
final isOnlineProvider = Provider<bool>((ref) {
  final state = ref.watch(connectivityProvider);
  return state == NetworkState.online;
});
