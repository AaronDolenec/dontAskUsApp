import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'api_provider.dart';

/// Auth state containing user info and session data
class AuthState {
  final User? user;
  final String? groupId;
  final bool isLoading;
  final String? error;
  final bool isAdmin;

  const AuthState({
    this.user,
    this.groupId,
    this.isLoading = false,
    this.error,
    this.isAdmin = false,
  });

  AuthState copyWith({
    User? user,
    String? groupId,
    bool? isLoading,
    String? error,
    bool? isAdmin,
  }) {
    return AuthState(
      user: user ?? this.user,
      groupId: groupId ?? this.groupId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  bool get isAuthenticated => user != null && groupId != null;
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _loadSession();
  }

  /// Load existing session from secure storage
  Future<void> _loadSession() async {
    state = state.copyWith(isLoading: true);

    try {
      final sessionInfo = await AuthService.getCurrentSessionInfo();
      final groupId = sessionInfo['groupId'];
      final token = sessionInfo['token'];

      // Refresh session token for all groups on app start
      final allGroups = await AuthService.getGroupsList();
      for (final gid in allGroups) {
        final t = await AuthService.getToken(gid);
        if (t != null) {
          await AuthService.refreshSession();
        }
      }

      if (groupId == null || token == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Validate session with API
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/api/users/validate-session/$token');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final validation = SessionValidation.fromJson(data);

        if (validation.valid) {
          final isAdmin = await AuthService.isAdmin(groupId);

          // Create a minimal user from validation data
          state = state.copyWith(
            user: User(
              id: 0,
              oderId: validation.oderId!,
              displayName: validation.displayName!,
              colorAvatar: '#3B82F6',
              sessionToken: token,
              createdAt: DateTime.now(),
              answerStreak: validation.answerStreak ?? 0,
              longestAnswerStreak: validation.longestAnswerStreak ?? 0,
            ),
            groupId: groupId,
            isLoading: false,
            isAdmin: isAdmin,
          );
          return;
        }
      }

      // Invalid session - clear it
      await AuthService.clearSession(groupId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore session',
      );
    }
  }

  /// Reload session (used when switching groups)
  Future<void> reloadSession() async {
    await _loadSession();
  }

  /// Join a group with invite code
  Future<bool> joinGroup({
    required String inviteCode,
    required String displayName,
    String? colorAvatar,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final api = _ref.read(apiClientProvider);

      // First, get the group info from the invite code
      final groupPreviewResponse = await api.get('/api/groups/$inviteCode');
      String? groupName;
      if (groupPreviewResponse.statusCode == 200) {
        final previewData =
            jsonDecode(groupPreviewResponse.body) as Map<String, dynamic>;
        groupName = previewData['name'] as String?;
      }

      final response = await api.post('/api/users/join', {
        'display_name': displayName,
        'group_invite_code': inviteCode.toUpperCase(),
        if (colorAvatar != null) 'color_avatar': colorAvatar,
      });

      // Debug: print response status
      print('Join API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data);

        // Get group ID from validating the new token
        final validateResponse = await api.get(
          '/api/users/validate-session/${user.sessionToken}',
        );

        print(
            'Validate response: ${validateResponse.statusCode} - ${validateResponse.body}');

        if (validateResponse.statusCode == 200) {
          final validateData =
              jsonDecode(validateResponse.body) as Map<String, dynamic>;
          final validation = SessionValidation.fromJson(validateData);

          if (validation.valid && validation.groupId != null) {
            // Save session with group name
            await AuthService.saveSession(
              groupId: validation.groupId!,
              token: user.sessionToken,
              oderId: user.oderId,
              displayName: user.displayName,
              groupName: groupName,
            );

            state = state.copyWith(
              user: user,
              groupId: validation.groupId,
              isLoading: false,
              isAdmin: false,
            );
            return true;
          } else {
            state = state.copyWith(
              isLoading: false,
              error:
                  'Session validation failed: ${validation.valid ? "missing group ID" : "invalid session"}',
            );
            return false;
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            error:
                'Failed to validate session (${validateResponse.statusCode})',
          );
          return false;
        }
      }

      final exception = ApiException.fromResponse(response);
      state = state.copyWith(
        isLoading: false,
        error: exception.userFriendlyMessage,
      );
      return false;
    } catch (e) {
      print('Join group error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Create a new group
  Future<Group?> createGroup(String name) async {
    state = state.copyWith(isLoading: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post('/api/groups', {'name': name});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final group = Group.fromJson(data);

        // Save admin token if provided
        if (group.adminToken != null) {
          await AuthService.saveAdminToken(group.groupId, group.adminToken!);
        }

        state = state.copyWith(isLoading: false);
        return group;
      }

      final exception = ApiException.fromResponse(response);
      state = state.copyWith(
        isLoading: false,
        error: exception.userFriendlyMessage,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Switch to a different group
  Future<bool> switchGroup(String groupId) async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await AuthService.getToken(groupId);
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No session found for this group',
        );
        return false;
      }

      // Validate the token
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/api/users/validate-session/$token');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final validation = SessionValidation.fromJson(data);

        if (validation.valid) {
          await AuthService.setCurrentGroup(groupId);
          final isAdmin = await AuthService.isAdmin(groupId);

          state = state.copyWith(
            user: User(
              id: 0,
              oderId: validation.oderId!,
              displayName: validation.displayName!,
              colorAvatar: '#3B82F6',
              sessionToken: token,
              createdAt: DateTime.now(),
              answerStreak: validation.answerStreak ?? 0,
              longestAnswerStreak: validation.longestAnswerStreak ?? 0,
            ),
            groupId: groupId,
            isLoading: false,
            isAdmin: isAdmin,
          );
          return true;
        }
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Invalid session for this group',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Leave the current group
  Future<void> leaveGroup() async {
    final groupId = state.groupId;
    if (groupId == null) return;

    await AuthService.clearSession(groupId);
    await CacheService.clearGroupCache(groupId);

    // Check if there are other groups
    final groups = await AuthService.getGroupsList();
    if (groups.isNotEmpty) {
      await switchGroup(groups.first);
    } else {
      state = const AuthState();
    }
  }

  /// Logout from all groups
  Future<void> logout() async {
    await AuthService.clearAllSessions();
    await CacheService.clearAllCache();
    state = const AuthState();
  }

  /// Update user streak
  void updateStreak(int currentStreak, int longestStreak) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(
        answerStreak: currentStreak,
        longestAnswerStreak: longestStreak,
      ),
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }
}

/// Provider for list of joined groups
final joinedGroupsProvider = FutureProvider<List<String>>((ref) async {
  return await AuthService.getGroupsList();
});

/// Provider for current session token
final sessionTokenProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return null;
  return await AuthService.getToken(auth.groupId!);
});

/// Provider for current admin token
final adminTokenProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return null;
  return await AuthService.getAdminToken(auth.groupId!);
});
