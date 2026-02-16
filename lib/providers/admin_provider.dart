import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../services/api_client.dart';
import 'dart:convert';
import 'api_provider.dart';

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref);
});

class AdminState {
  final bool isLoggedIn;
  final String? token;
  final Map<String, dynamic>? dashboardStats;
  final List<dynamic>? auditLogs;
  AdminState({
    this.isLoggedIn = false,
    this.token,
    this.dashboardStats,
    this.auditLogs,
  });

  AdminState copyWith({
    bool? isLoggedIn,
    String? token,
    Map<String, dynamic>? dashboardStats,
    List<dynamic>? auditLogs,
  }) {
    return AdminState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final Ref ref;
  AdminNotifier(this.ref) : super(AdminState());

  Future<void> login(String username, String password) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post('/api/admin/login', {
      'username': username,
      'password': password,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'] ?? data['temp_token'];
      state = state.copyWith(isLoggedIn: true, token: token);
    }
  }

  Future<void> fetchDashboardStats() async {
    if (state.token == null) return;
    final api = ref.read(apiClientProvider);
    final response =
        await api.get('/api/admin/dashboard/stats', accessToken: state.token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(dashboardStats: data);
    }
  }

  Future<void> fetchAuditLogs({int limit = 50, int offset = 0}) async {
    if (state.token == null) return;
    final api = ref.read(apiClientProvider);
    final response = await api.get(
        '/api/admin/audit-logs?limit=$limit&offset=$offset',
        accessToken: state.token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(auditLogs: data['logs']);
    }
  }
}
