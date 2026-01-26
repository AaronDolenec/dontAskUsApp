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

  /// Debug method to print all stored auth data
  Future<void> _debugPrintStorage() async {
    await AuthService.debugPrintStorage();
  }

  /// Load existing session from secure storage
  Future<void> _loadSession() async {
    state = state.copyWith(isLoading: true);

    try {
      // Debug: Print all stored keys
      await _debugPrintStorage();

      // Get all stored groups
      final allGroups = await AuthService.getGroupsList();
      debugPrint('DEBUG: Found stored groups: $allGroups');

      if (allGroups.isEmpty) {
        // No groups stored, user needs to join/create a group
        debugPrint('DEBUG: No stored groups found');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Check if we have a current group set
      final currentGroupId = await AuthService.getCurrentGroupId();
      debugPrint('DEBUG: Current group ID: $currentGroupId');

      // If no current group is set but we have groups, set the first one as current
      String? groupId = currentGroupId;
      if (groupId == null && allGroups.isNotEmpty) {
        groupId = allGroups.first;
        await AuthService.setCurrentGroup(groupId);
        debugPrint('DEBUG: Set current group to: $groupId');
      }

      if (groupId == null) {
        debugPrint('DEBUG: No group ID available');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Get token for the current group
      final token = await AuthService.getToken(groupId);
      debugPrint(
          'DEBUG: Token for group $groupId: ${token != null ? "exists" : "null"}');

      if (token == null) {
        debugPrint('DEBUG: No token found for group $groupId');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Validate session with API
      debugPrint(
          'DEBUG: Validating session with API for token: ${token.substring(0, 10)}...');
      final api = _ref.read(apiClientProvider);
      final response = await api.get('/api/users/validate-session/$token');
      debugPrint('DEBUG: API response status: ${response.statusCode}');
      debugPrint('DEBUG: API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final validation = SessionValidation.fromJson(data);
        debugPrint('DEBUG: Session validation result: ${validation.valid}');
        debugPrint(
            'DEBUG: Validation data: user_id=${validation.oderId}, display_name=${validation.displayName}, group_id=${validation.groupId}');

        if (validation.valid) {
          final isAdmin = await AuthService.isAdmin(groupId);
          debugPrint('DEBUG: User is admin: $isAdmin');

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
      } else {
        debugPrint(
            'DEBUG: API validation failed with status ${response.statusCode}');
        debugPrint('DEBUG: Response body: ${response.body}');
        debugPrint('DEBUG: Response headers: ${response.headers}');

        // If 401, try to refresh the token
        if (response.statusCode == 401) {
          debugPrint('DEBUG: Token expired (401), attempting to refresh...');
          final refreshResult = await AuthService.refreshSession();
          if (refreshResult != null) {
            debugPrint(
                'DEBUG: Token refreshed successfully, retrying validation...');
            // Retry validation with refreshed token
            final newToken = await AuthService.getToken(groupId);
            if (newToken != null && newToken != token) {
              final retryResponse =
                  await api.get('/api/users/validate-session/$newToken');
              debugPrint(
                  'DEBUG: Retry validation status: ${retryResponse.statusCode}');
              if (retryResponse.statusCode == 200) {
                final retryData =
                    jsonDecode(retryResponse.body) as Map<String, dynamic>;
                final retryValidation = SessionValidation.fromJson(retryData);
                debugPrint(
                    'DEBUG: Retry validation result: ${retryValidation.valid}');

                if (retryValidation.valid) {
                  final isAdmin = await AuthService.isAdmin(groupId);
                  debugPrint('DEBUG: User is admin: $isAdmin');

                  // Create a minimal user from validation data
                  state = state.copyWith(
                    user: User(
                      id: 0,
                      oderId: retryValidation.oderId!,
                      displayName: retryValidation.displayName!,
                      colorAvatar: '#3B82F6',
                      sessionToken: newToken,
                      createdAt: DateTime.now(),
                      answerStreak: retryValidation.answerStreak ?? 0,
                      longestAnswerStreak:
                          retryValidation.longestAnswerStreak ?? 0,
                    ),
                    groupId: groupId,
                    isLoading: false,
                    isAdmin: isAdmin,
                  );
                  return;
                }
              }
            }
          }
          debugPrint('DEBUG: Token refresh failed or retry validation failed');
        }
      }

      // Invalid session - clear it and try next group if available
      debugPrint(
          'DEBUG: Session invalid for group $groupId, clearing and trying other groups');
      await AuthService.clearSession(groupId);

      // Try other groups
      for (final nextGroupId in allGroups.where((g) => g != groupId)) {
        debugPrint('DEBUG: Trying group $nextGroupId');
        final nextToken = await AuthService.getToken(nextGroupId);
        debugPrint(
            'DEBUG: Token for group $nextGroupId: ${nextToken != null ? "exists" : "null"}');
        if (nextToken != null) {
          // Validate session for this group
          final api = _ref.read(apiClientProvider);
          final response =
              await api.get('/api/users/validate-session/$nextToken');
          debugPrint(
              'DEBUG: Validation for group $nextGroupId status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final validation = SessionValidation.fromJson(data);

            if (validation.valid) {
              final isAdmin = await AuthService.isAdmin(nextGroupId);
              await AuthService.setCurrentGroup(nextGroupId);

              // Create a minimal user from validation data
              state = state.copyWith(
                user: User(
                  id: 0,
                  oderId: validation.oderId!,
                  displayName: validation.displayName!,
                  colorAvatar: '#3B82F6',
                  sessionToken: nextToken,
                  createdAt: DateTime.now(),
                  answerStreak: validation.answerStreak ?? 0,
                  longestAnswerStreak: validation.longestAnswerStreak ?? 0,
                ),
                groupId: nextGroupId,
                isLoading: false,
                isAdmin: isAdmin,
              );
              return;
            }
          } else if (response.statusCode == 401) {
            // Try to refresh token for this group
            debugPrint(
                'DEBUG: Token expired for group $nextGroupId, attempting refresh...');
            await AuthService.setCurrentGroup(
                nextGroupId); // Temporarily set as current for refresh
            final refreshResult = await AuthService.refreshSession();
            if (refreshResult != null) {
              debugPrint(
                  'DEBUG: Token refreshed for group $nextGroupId, retrying validation...');
              final refreshedToken = await AuthService.getToken(nextGroupId);
              if (refreshedToken != null) {
                final retryResponse = await api
                    .get('/api/users/validate-session/$refreshedToken');
                if (retryResponse.statusCode == 200) {
                  final retryData =
                      jsonDecode(retryResponse.body) as Map<String, dynamic>;
                  final retryValidation = SessionValidation.fromJson(retryData);

                  if (retryValidation.valid) {
                    final isAdmin = await AuthService.isAdmin(nextGroupId);

                    // Create a minimal user from validation data
                    state = state.copyWith(
                      user: User(
                        id: 0,
                        oderId: retryValidation.oderId!,
                        displayName: retryValidation.displayName!,
                        colorAvatar: '#3B82F6',
                        sessionToken: refreshedToken,
                        createdAt: DateTime.now(),
                        answerStreak: retryValidation.answerStreak ?? 0,
                        longestAnswerStreak:
                            retryValidation.longestAnswerStreak ?? 0,
                      ),
                      groupId: nextGroupId,
                      isLoading: false,
                      isAdmin: isAdmin,
                    );
                    return;
                  }
                }
              }
            }
          }
          // Clear invalid session for this group too
          await AuthService.clearSession(nextGroupId);
        }
      }

      // No valid sessions found
      debugPrint('DEBUG: No valid sessions found for any group');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('DEBUG: Error during session loading: $e');
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data);

        // Wait a bit for server to process the join
        await Future.delayed(const Duration(seconds: 2));

        // Get group ID from validating the new token
        final validateResponse = await api.get(
          '/api/users/validate-session/${user.sessionToken}',
        );

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
