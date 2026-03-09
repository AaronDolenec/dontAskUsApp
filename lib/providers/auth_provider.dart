import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'api_provider.dart';
import 'group_provider.dart';

/// Auth state containing user info and session data
class AuthState {
  final User? user;
  final String? groupId;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.groupId,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? groupId,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      groupId: groupId ?? this.groupId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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

  String _friendlyError(Object error, {String? fallback}) {
    if (error is ApiException) {
      return error.userFriendlyMessage;
    }

    final raw = error.toString();
    final text = raw.toLowerCase();

    if (text.contains('xmlhttprequest error') ||
        text.contains('failed to fetch') ||
        text.contains('network error') ||
        text.contains('socketexception') ||
        text.contains('connection refused')) {
      return 'Network error. Please check your connection and server URL.';
    }

    if (text.contains('instance of minified') || text.contains('minified:')) {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    if (raw.isEmpty || raw == 'null') {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    return raw;
  }

  /// Load existing session from secure storage
  Future<void> _loadSession() async {
    state = state.copyWith(isLoading: true);

    try {
      // Wait for bootstrap (dotenv, etc.) so that ApiConfig has the correct
      // server URL before we make any network requests.
      await AppBootstrapService.ensureInitialized();

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
        debugPrint('DEBUG: /api/auth/me response keys=${data.keys.toList()}');
        final user = User.fromMeJson(data);
        debugPrint(
            'DEBUG: _loadSession user.id=${user.id}, user.oderId=${user.oderId}');

        // Sync group memberships from server
        await Future.wait(
          user.groups.map(
            (group) => AuthService.saveGroupMembership(
              groupId: group.groupId,
              userId: group.userId,
              displayName: group.displayName,
              groupName: group.groupName,
            ),
          ),
        );

        // Determine current group
        final sessionValues = await Future.wait<dynamic>([
          AuthService.getCurrentGroupId(),
          AuthService.getGroupsList(),
        ]);
        String? groupId = sessionValues[0] as String?;
        final allGroups = sessionValues[1] as List<String>;

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
          state = state.copyWith(
            user: user,
            groupId: groupId,
            isLoading: false,
          );
          // Enrich user with avatar/streak from group members (async, non-blocking)
          _enrichUserFromGroupMembers(groupId, accessToken);
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
          isLoading: true,
          error: 'Network error. Retrying in ${retryDelay.inSeconds}s...',
        );

        Future.delayed(retryDelay, () => _loadSession());
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(
          e,
          fallback: 'Failed to restore session. Please sign in again.',
        ),
      );
    }
  }

  /// Reload session (used when switching groups)
  Future<void> reloadSession() async {
    _loadSessionRetries = 0;
    await _loadSession();
  }

  /// Enrich the auth user with avatar_url and streak data from group members.
  /// /api/auth/me may not return these fields, but /api/groups/{id}/members does.
  Future<void> _enrichUserFromGroupMembers(
      String groupId, String accessToken) async {
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/groups/$groupId/members',
        accessToken: accessToken,
      );
      if (response.statusCode == 200 && state.user != null) {
        final data = jsonDecode(response.body);
        List membersJson;
        if (data is Map<String, dynamic> && data.containsKey('members')) {
          membersJson = data['members'] as List? ?? [];
        } else if (data is List) {
          membersJson = data;
        } else {
          return;
        }
        final members = membersJson
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();

        // Find current user by display name
        final me = members.cast<GroupMember?>().firstWhere(
              (m) => m!.displayName == state.user!.displayName,
              orElse: () => null,
            );
        if (me != null) {
          final needsUpdate = (state.user!.avatarUrl == null &&
                  me.avatarUrl != null &&
                  me.avatarUrl!.isNotEmpty) ||
              state.user!.answerStreak != me.answerStreak ||
              state.user!.longestAnswerStreak != me.longestAnswerStreak;
          if (needsUpdate) {
            state = state.copyWith(
              user: state.user!.copyWith(
                avatarUrl: me.avatarUrl ?? state.user!.avatarUrl,
                answerStreak: me.answerStreak,
                longestAnswerStreak: me.longestAnswerStreak,
              ),
            );
            debugPrint(
                'DEBUG: Enriched user from members: avatar=${me.avatarUrl}, streak=${me.answerStreak}');
          }
        }

        // Also cache members for other providers
        await CacheService.cacheMembers(groupId, members);
      }
    } catch (e) {
      debugPrint('DEBUG: Failed to enrich user from members: $e');
    }
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
        error: _friendlyError(e, fallback: 'Registration failed.'),
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
        error: _friendlyError(e, fallback: 'Login failed. Please try again.'),
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

    // Extract the nested user object (login/register responses wrap it)
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    debugPrint('DEBUG: _handleAuthResponse keys=${data.keys.toList()}');
    debugPrint('DEBUG: _handleAuthResponse userData=$userData');

    // Parse user
    final user = User.fromAuthJson(userData);
    debugPrint(
        'DEBUG: _handleAuthResponse user.id=${user.id}, user.oderId=${user.oderId}');

    // Save account info
    await AuthService.saveAccountInfo(
      accountId: user.oderId,
      email: user.email ?? '',
      displayName: user.displayName,
    );

    // Save group memberships
    await Future.wait(
      user.groups.map(
        (group) => AuthService.saveGroupMembership(
          groupId: group.groupId,
          userId: group.userId,
          displayName: group.displayName,
          groupName: group.groupName,
        ),
      ),
    );

    // Set current group
    String? currentGroupId;
    if (user.groups.isNotEmpty) {
      currentGroupId = user.groups.first.groupId;
      await AuthService.setCurrentGroup(currentGroupId);
    }

    state = state.copyWith(
      user: user,
      groupId: currentGroupId,
      isLoading: false,
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
        error: _friendlyError(e, fallback: 'Failed to join group.'),
      );
      return false;
    }
  }

  /// Create a new group
  /// Create a new group. Optionally specify a default displayName for
  /// members (including the creator).
  Future<Group?> createGroup(String name, {String? displayName}) async {
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
      final body = {'name': name};
      if (displayName != null) {
        body['display_name'] = displayName;
      }
      final response = await api.post(
        '/api/auth/groups/create',
        body,
        accessToken: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final group = Group.fromJson(data);

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

          state = state.copyWith(
            user: user,
            groupId: group.groupId,
            isLoading: false,
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
        error: _friendlyError(e, fallback: 'Failed to create group.'),
      );
      return null;
    }
  }

  /// Update the current user's display name for the active group.
  Future<bool> updateDisplayName(String newName) async {
    final groupId = state.groupId;
    final userId = _resolveCurrentUserIdForSettings();
    if (groupId == null) return false;
    if (userId == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) return false;

      final api = _ref.read(apiClientProvider);
      final response = await api.put(
        '/api/users/$userId/display-name',
        {'display_name': newName},
        accessToken: accessToken,
      );
      if (response.statusCode == 200) {
        final currentUser = state.user;
        if (currentUser == null) {
          state = state.copyWith(isLoading: false);
          return true;
        }

        final updatedGroups = currentUser.groups
            .map((g) => g.groupId == groupId
                ? UserGroupMembership(
                    userId: g.userId,
                    groupId: g.groupId,
                    groupName: g.groupName,
                    displayName: newName,
                  )
                : g)
            .toList();

        final updatedCurrentGroup =
            updatedGroups.cast<UserGroupMembership?>().firstWhere(
                  (g) => g?.groupId == groupId,
                  orElse: () => null,
                );

        // update local storage
        await AuthService.saveGroupMembership(
          groupId: groupId,
          userId: userId,
          displayName: newName,
          groupName: updatedCurrentGroup?.groupName ?? '',
        );

        state = state.copyWith(
          user: currentUser.copyWith(
            displayName: newName,
            groups: updatedGroups,
          ),
          isLoading: false,
        );

        // Refresh cached members so UI reflects updated name everywhere.
        _ref.invalidate(groupMembersProvider);
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  /// Fetch notification settings for the current user/group.
  Future<NotificationSettings?> fetchNotificationSettings() async {
    final userId = _resolveCurrentUserIdForSettings();
    if (userId == null) return null;
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) return null;
      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/users/$userId/settings',
        accessToken: accessToken,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NotificationSettings.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Update notification settings on the server.
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    final userId = _resolveCurrentUserIdForSettings();
    if (userId == null) return false;
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) return false;
      final api = _ref.read(apiClientProvider);

      final emailResponse = await api.put(
        '/api/users/$userId/email-settings',
        {
          'email_on_new_question': settings.emailOnNewQuestion,
          'email_on_reminder': settings.emailOnReminder,
        },
        accessToken: accessToken,
      );

      if (emailResponse.statusCode != 200) {
        return false;
      }

      final pushResponse = await api.put(
        '/api/users/$userId/push-settings',
        {
          'push_notifications_enabled': settings.pushNotificationsEnabled,
        },
        accessToken: accessToken,
      );

      return pushResponse.statusCode == 200;
    } catch (_) {}
    return false;
  }

  String? _resolveCurrentUserIdForSettings() {
    final user = state.user;
    if (user == null) return null;

    final groupId = state.groupId;
    if (groupId != null) {
      for (final membership in user.groups) {
        if (membership.groupId == groupId && membership.userId.isNotEmpty) {
          return membership.userId;
        }
      }
    }

    return user.oderId.isNotEmpty ? user.oderId : null;
  }

  /// Switch to a different group
  Future<bool> switchGroup(String groupId) async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthService.setCurrentGroup(groupId);
      final displayName = await AuthService.getDisplayName(groupId);
      final userId = await AuthService.getUserId(groupId);

      state = state.copyWith(
        user: state.user?.copyWith(
          oderId: userId ?? state.user!.oderId,
          displayName: displayName ?? state.user!.displayName,
        ),
        groupId: groupId,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e, fallback: 'Could not switch group.'),
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

  /// Update avatar color locally
  void updateAvatarColor(String hexColor) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(colorAvatar: hexColor),
    );
  }

  /// Upload a new avatar image
  Future<String?> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    if (state.user == null) return 'Not logged in';
    try {
      String? accessToken = await AuthService.getAccessToken();
      if (accessToken == null) return 'Not authenticated';
      final api = _ref.read(apiClientProvider);
      final userId = state.user!.oderId; // account_id as string
      debugPrint(
          'DEBUG: uploadAvatar userId=$userId, user.id=${state.user!.id}, fileName=$fileName, bytes=${fileBytes.length}');
      debugPrint(
          'DEBUG: uploadAvatar token=${accessToken.substring(0, 20)}...');
      var response = await api.postMultipartBytes(
        '/api/users/$userId/avatar',
        fileBytes: fileBytes,
        fileName: fileName,
        fileField: 'file',
        accessToken: accessToken,
      );
      debugPrint('DEBUG: uploadAvatar response status=${response.statusCode}');
      debugPrint('DEBUG: uploadAvatar response body=${response.body}');

      // If 401, try refreshing the token and retry once
      if (response.statusCode == 401) {
        debugPrint('DEBUG: uploadAvatar got 401, attempting token refresh...');
        final refreshResult = await AuthService.refreshSession();
        if (refreshResult != null) {
          accessToken = await AuthService.getAccessToken();
          if (accessToken != null) {
            response = await api.postMultipartBytes(
              '/api/users/$userId/avatar',
              fileBytes: fileBytes,
              fileName: fileName,
              fileField: 'file',
              accessToken: accessToken,
            );
            debugPrint(
                'DEBUG: uploadAvatar retry status=${response.statusCode}');
            debugPrint('DEBUG: uploadAvatar retry body=${response.body}');
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final avatarUrl = data['avatar_url'] as String?;
        if (avatarUrl != null) {
          state = state.copyWith(
            user: state.user!.copyWith(avatarUrl: avatarUrl),
          );
        }
        // Defer invalidation to next microtask to avoid circular dependency
        // between authProvider state change and groupMembersProvider watch
        Future.microtask(() => _ref.invalidate(groupMembersProvider));
        return null; // success
      }
      final exception = ApiException.fromResponse(response);
      return exception.userFriendlyMessage;
    } catch (e) {
      return _friendlyError(e, fallback: 'Upload failed. Please try again.');
    }
  }

  /// Delete the user's avatar, reverting to color avatar
  Future<String?> deleteAvatar() async {
    if (state.user == null) return 'Not logged in';
    try {
      String? accessToken = await AuthService.getAccessToken();
      if (accessToken == null) return 'Not authenticated';
      final api = _ref.read(apiClientProvider);
      final userId = state.user!.oderId; // account_id as string
      var response = await api.delete(
        '/api/users/$userId/avatar',
        accessToken: accessToken,
      );

      // If 401, try refreshing the token and retry once
      if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshSession();
        if (refreshResult != null) {
          accessToken = await AuthService.getAccessToken();
          if (accessToken != null) {
            response = await api.delete(
              '/api/users/$userId/avatar',
              accessToken: accessToken,
            );
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final colorAvatar =
            data['color_avatar'] as String? ?? state.user!.colorAvatar;
        // Build a new User directly to set avatarUrl to null (copyWith keeps old value for null params)
        state = state.copyWith(
          user: User(
            id: state.user!.id,
            oderId: state.user!.oderId,
            displayName: state.user!.displayName,
            colorAvatar: colorAvatar,
            // avatarUrl intentionally omitted — defaults to null, clearing the avatar
            email: state.user!.email,
            createdAt: state.user!.createdAt,
            answerStreak: state.user!.answerStreak,
            longestAnswerStreak: state.user!.longestAnswerStreak,
            groups: state.user!.groups,
          ),
        );
        // Defer invalidation to next microtask to avoid circular dependency
        Future.microtask(() => _ref.invalidate(groupMembersProvider));
        return null; // success
      }
      final exception = ApiException.fromResponse(response);
      return exception.userFriendlyMessage;
    } catch (e) {
      return _friendlyError(e, fallback: 'Failed to remove avatar.');
    }
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
