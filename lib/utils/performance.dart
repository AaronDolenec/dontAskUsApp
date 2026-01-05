import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring and optimization utilities
class PerformanceUtils {
  PerformanceUtils._();

  static final _stopwatches = <String, Stopwatch>{};

  /// Start timing an operation
  static void startTimer(String label) {
    _stopwatches[label] = Stopwatch()..start();
  }

  /// Stop timing and log the result
  static Duration stopTimer(String label, {bool log = true}) {
    final stopwatch = _stopwatches.remove(label);
    if (stopwatch == null) {
      return Duration.zero;
    }
    stopwatch.stop();
    if (log && kDebugMode) {
      debugPrint('⏱️ $label: ${stopwatch.elapsedMilliseconds}ms');
    }
    return stopwatch.elapsed;
  }

  /// Run a function and measure its execution time
  static T measureSync<T>(String label, T Function() fn) {
    startTimer(label);
    try {
      return fn();
    } finally {
      stopTimer(label);
    }
  }

  /// Run an async function and measure its execution time
  static Future<T> measureAsync<T>(
      String label, Future<T> Function() fn) async {
    startTimer(label);
    try {
      return await fn();
    } finally {
      stopTimer(label);
    }
  }

  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Check if running in profile mode
  static bool get isProfileMode => kProfileMode;

  /// Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;
}

/// Debouncer for rate-limiting function calls
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({this.duration = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Throttler for limiting function call frequency
class Throttler {
  final Duration duration;
  DateTime? _lastRun;
  Timer? _timer;

  Throttler({this.duration = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    } else {
      _timer?.cancel();
      _timer = Timer(duration - now.difference(_lastRun!), () {
        _lastRun = DateTime.now();
        action();
      });
    }
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Lazy loader for expensive objects
class LazyLoader<T> {
  final T Function() _factory;
  T? _value;
  bool _initialized = false;

  LazyLoader(this._factory);

  T get value {
    if (!_initialized) {
      _value = _factory();
      _initialized = true;
    }
    return _value as T;
  }

  bool get isInitialized => _initialized;

  void reset() {
    _value = null;
    _initialized = false;
  }
}

/// Cache with expiration
class ExpiringCache<K, V> {
  final Duration expiration;
  final Map<K, _CacheEntry<V>> _cache = {};

  ExpiringCache({this.expiration = const Duration(minutes: 5)});

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  void set(K key, V value) {
    _cache[key] = _CacheEntry(value, DateTime.now().add(expiration));
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void cleanup() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  int get size => _cache.length;
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Frame callback scheduler for smooth animations
class FrameScheduler {
  static bool _isScheduled = false;
  static final List<VoidCallback> _callbacks = [];

  /// Schedule a callback to run on the next frame
  static void scheduleFrame(VoidCallback callback) {
    _callbacks.add(callback);
    if (!_isScheduled) {
      _isScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _isScheduled = false;
        final callbacks = List<VoidCallback>.from(_callbacks);
        _callbacks.clear();
        for (final callback in callbacks) {
          callback();
        }
      });
    }
  }
}

/// Memory-efficient list operations
extension ListPerformanceExtensions<T> on List<T> {
  /// Lazy where that doesn't create intermediate list
  Iterable<T> lazyWhere(bool Function(T) test) sync* {
    for (final item in this) {
      if (test(item)) yield item;
    }
  }

  /// Lazy map that doesn't create intermediate list
  Iterable<R> lazyMap<R>(R Function(T) transform) sync* {
    for (final item in this) {
      yield transform(item);
    }
  }

  /// Chunked iteration for large lists
  Iterable<List<T>> chunked(int size) sync* {
    for (var i = 0; i < length; i += size) {
      yield sublist(i, (i + size).clamp(0, length));
    }
  }
}

/// Image optimization helper
class ImageOptimization {
  ImageOptimization._();

  /// Get optimal cache dimensions based on device pixel ratio
  static int getCacheWidth(double displayWidth, double devicePixelRatio) {
    return (displayWidth * devicePixelRatio).ceil();
  }

  /// Get optimal cache height based on device pixel ratio
  static int getCacheHeight(double displayHeight, double devicePixelRatio) {
    return (displayHeight * devicePixelRatio).ceil();
  }

  /// Memory budget in bytes for image cache (50MB default)
  static const int defaultMemoryBudget = 50 * 1024 * 1024;
}

/// Build optimization helper
class BuildOptimization {
  BuildOptimization._();

  /// Check if widget should rebuild based on equality
  static bool shouldRebuild<T>(T? oldValue, T? newValue) {
    if (identical(oldValue, newValue)) return false;
    if (oldValue == null || newValue == null) return true;
    return oldValue != newValue;
  }

  /// Batch multiple setState calls
  static void batchedSetState(
    void Function(VoidCallback) setState,
    List<VoidCallback> updates,
  ) {
    setState(() {
      for (final update in updates) {
        update();
      }
    });
  }
}
