import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

/// Provider for the API client
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(() => client.dispose());
  return client;
});
