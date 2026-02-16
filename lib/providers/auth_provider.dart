import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
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

  bool get isAuthenticated => user != null;
  bool get hasGroup => user != null && groupId != null;
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  int _loadSessionRetries = 0;
  static const _maxLoadSessionRetries = 3;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _loadSession();
  }

  /// Load existing session from secure storage
  Future<void> _loadSession() async {
    state = state.copyWith(isLoading: true);

    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('DEBUG: No access token found');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Validate token by calling /api/auth/me
      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/auth/me',
        accessToken: accessToken,
      );
      debugPrint('DEBUG: /api/auth/me response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromMeJson(data);

        // Sync group memberships from server
        for (final group in user.groups) {
          await AuthService.saveGroupMembership(
            groupId: group.groupId,
            userId: group.userId,
            displayName: group.displayName,
            groupName: group.groupName,
          );
        }

        // Determine current group
        String? groupId = await AuthService.getCurrentGroupId();
        final allGroups = await AuthService.getGroupsList();

        if (groupId == null || !allGroups.contains(groupId)) {
          if (user.groups.isNotEmpty) {
            groupId = user.groups.first.groupId;
            await AuthService.setCurrentGroup(groupId);
          } else if (allGroups.isNotEmpty) {
            groupId = allGroups.first;
            await AuthService.setCurrentGroup(groupId);
          }
        }

        if (groupId != null) {
          final isAdmin = await AuthService.isAdmin(groupId);
          state = state.copyWith(
            user: user,
            groupId: groupId,
            isLoading: false,
            isAdmin: isAdmin,
          );
          return;
        }

        // User has no groups yet - still authenticated
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
        return;
      } else if (response.statusCode == 401) {
        debugPrint('DEBUG: Access token expired, attempting refresh...');
        final refreshResult = await AuthService.refreshSession();
        if (refreshResult != null) {
          debugPrint('DEBUG: Token refreshed, retrying...');
          _loadSessionRetries = 0;
          await _loadSession();
          return;
        }
        debugPrint('DEBUG: Token refresh failed');
      }

      // Token invalid or expired and refresh failed
      debugPrint('DEBUG: No valid session found');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('DEBUG: Error during session loading: $e');

      final isNetworkError = e is ApiException && e.statusCode == 0 ||
          e.toString().toLowerCase().contains('network error');

      if (isNetworkError && _loadSessionRetries < _maxLoadSessionRetries) {
        _loadSessionRetries += 1;
        final retryDelay = Duration(seconds: 3 * _loadSessionRetries);
        debugPrint(
            'DEBUG: Network error, retry #$_loadSessionRetries in ${retryDelay.inSeconds}s');

        state = state.copyWith(
          isLoading: false,
          error: 'Network error. Retrying in ${retryDelay.inSeconds}s...',
        );

        Future.delayed(retryDelay, () => _loadSession());
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore session',
      );
    }
  }

  /// Reload session (used when switching groups)
  Future<void> reloadSession() async {
    _loadSessionRetries = 0;
    await _loadSession();
  }

  /// Register a new account
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post('/api/auth/register', {
        'email': email,
        'password': password,
        'display_name': displayName,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _handleAuthResponse(data);
        return true;
      }

      final exception = ApiException.fromResponse(response);
      state = state.copyWith(
        isLoading: false,
        error: exception.userFriendlyMessage,
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

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.post('/api/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _handleAuthResponse(data);
        return true;
      }

      final exception = ApiException.fromResponse(response);
      state = state.copyWith(
        isLoading: false,
        error: exception.userFriendlyMessage,
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

  /// Handle auth response (login/register)
  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;

    // Save tokens
    await AuthService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Parse user from top-level fields (register/login response is flat)
    final user = User.fromAuthJson(data);

    // Save account info
    await AuthService.saveAccountInfo(
      accountId: user.oderId,
      email: user.email ?? '',
      displayName: user.displayName,
    );

    // Save group memberships
    for (final group in user.groups) {
      await AuthService.saveGroupMembership(
        groupId: group.groupId,
        userId: group.userId,
        displayName: group.displayName,
        groupName: group.groupName,
      );
    }

    // Set current group
    String? currentGroupId;
    if (user.groups.isNotEmpty) {
      currentGroupId = user.groups.first.groupId;
      await AuthService.setCurrentGroup(currentGroupId);
    }

    final isAdmin = currentGroupId != null
        ? await AuthService.isAdmin(currentGroupId)
        : false;

    state = state.copyWith(
      user: user,
      groupId: currentGroupId,
      isLoading: false,
      isAdmin: isAdmin,
    );
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) return false;

      final api = _ref.read(apiClientProvider);
      final response = await api.post(
        '/api/auth/change-password',
        {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        accessToken: accessToken,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Join a group with invite code
  Future<bool> joinGroup({
    required String inviteCode,
    required String displayName,
    String? colorAvatar,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not logged in. Please login first.',
        );
        return false;
      }

      final api = _ref.read(apiClientProvider);
      final response = await api.post(
        '/api/auth/groups/join',
        {
          'invite_code': inviteCode.toUpperCase(),
          'display_name': displayName,
          if (colorAvatar != null) 'color_avatar': colorAvatar,
        },
        accessToken: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final groupId = (data['group_id'] ?? '').toString();
        final userId = (data['user_id'] ?? '').toString();
        final groupName = data['group_name'] as String? ?? '';
        final memberDisplayName =
            data['display_name'] as String? ?? displayName;

        await AuthService.saveGroupMembership(
          groupId: groupId,
          userId: userId,
          displayName: memberDisplayName,
          groupName: groupName,
        );

        final isAdmin = await AuthService.isAdmin(groupId);

        // Refresh user info
        final meResponse = await api.get(
          '/api/auth/me',
          accessToken: accessToken,
        );
        User user = state.user ??
            User(
              id: 0,
              oderId: userId,
              displayName: memberDisplayName,
              colorAvatar: colorAvatar ?? '#3B82F6',
              createdAt: DateTime.now(),
            );

        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body) as Map<String, dynamic>;
          user = User.fromMeJson(meData);
        }

        state = state.copyWith(
          user: user,
          groupId: groupId,
          isLoading: false,
          isAdmin: isAdmin,
        );
        return true;
      }

      final exception = ApiException.fromResponse(response);
      state = state.copyWith(
        isLoading: false,
        error: exception.userFriendlyMessage,
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

  /// Create a new group
  Future<Group?> createGroup(String name) async {
    state = state.copyWith(isLoading: true);

    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not logged in. Please login first.',
        );
        return null;
      }

      final api = _ref.read(apiClientProvider);
      final response = await api.post(
        '/api/auth/groups/create',
        {'name': name},
        accessToken: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final group = Group.fromJson(data);

        if (group.adminToken != null) {
          await AuthService.saveAdminToken(group.groupId, group.adminToken!);
        }

        // Refresh user info to get updated groups list
        final meResponse = await api.get(
          '/api/auth/me',
          accessToken: accessToken,
        );
        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body) as Map<String, dynamic>;
          final user = User.fromMeJson(meData);

          // Save group memberships
          for (final g in user.groups) {
            await AuthService.saveGroupMembership(
              groupId: g.groupId,
              userId: g.userId,
              displayName: g.displayName,
              groupName: g.groupName,
            );
          }

          await AuthService.setCurrentGroup(group.groupId);
          final isAdmin = await AuthService.isAdmin(group.groupId);

          state = state.copyWith(
            user: user,
            groupId: group.groupId,
            isLoading: false,
            isAdmin: isAdmin,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }

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
      await AuthService.setCurrentGroup(groupId);
      final isAdmin = await AuthService.isAdmin(groupId);
      final displayName = await AuthService.getDisplayName(groupId);
      final userId = await AuthService.getUserId(groupId);

      state = state.copyWith(
        user: state.user?.copyWith(
          oderId: userId ?? state.user!.oderId,
          displayName: displayName ?? state.user!.displayName,
        ),
        groupId: groupId,
        isLoading: false,
        isAdmin: isAdmin,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Recover account using a raw session token (legacy support)
  Future<bool> recoverWithToken(String token) async {
    state = state.copyWith(isLoading: true);

    try {
      // Try treating the token as an access token
      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/auth/me',
        accessToken: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromMeJson(data);

        // Save the token
        await AuthService.saveTokens(
          accessToken: token,
          refreshToken: '', // No refresh token available in recovery
        );

        await AuthService.saveAccountInfo(
          accountId: user.oderId,
          email: user.email ?? '',
          displayName: user.displayName,
        );

        for (final group in user.groups) {
          await AuthService.saveGroupMembership(
            groupId: group.groupId,
            userId: group.userId,
            displayName: group.displayName,
            groupName: group.groupName,
          );
        }

        String? groupId;
        if (user.groups.isNotEmpty) {
          groupId = user.groups.first.groupId;
          await AuthService.setCurrentGroup(groupId);
        }

        final isAdmin =
            groupId != null ? await AuthService.isAdmin(groupId) : false;

        state = state.copyWith(
          user: user,
          groupId: groupId,
          isLoading: false,
          isAdmin: isAdmin,
        );
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'Invalid token');
      return false;
    } catch (e) {
      debugPrint('DEBUG: recoverWithToken error: $e');

      final isNetworkError = e is ApiException && e.statusCode == 0 ||
          e.toString().toLowerCase().contains('network error');

      state = state.copyWith(
        isLoading: false,
        error:
            isNetworkError ? 'Network error. Please try again.' : e.toString(),
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

    final groups = await AuthService.getGroupsList();
    if (groups.isNotEmpty) {
      await switchGroup(groups.first);
    } else {
      state = AuthState(
        user: state.user,
      );
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

/// Provider for current access token
final accessTokenProvider = FutureProvider<String?>((ref) async {
  ref.watch(authProvider); // Re-evaluate when auth changes
  return await AuthService.getAccessToken();
});

/// Provider for current admin token
final adminTokenProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return null;
  return await AuthService.getAdminToken(auth.groupId!);
});

/// Legacy alias
final sessionTokenProvider = accessTokenProvider;
