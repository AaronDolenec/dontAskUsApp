import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_client.dart';

/// Abstract storage interface for cross-platform compatibility
abstract class _StorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Secure storage for mobile platforms
class _SecureStorageBackend implements _StorageBackend {
  final FlutterSecureStorage _storage;

  _SecureStorageBackend(this._storage);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// SharedPreferences fallback for web (non-secure context)
class _WebStorageBackend implements _StorageBackend {
  SharedPreferences? _prefs;
  static const _prefix = 'auth_';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<String?> read(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString('$_prefix$key');
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString('$_prefix$key', value);
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove('$_prefix$key');
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

/// Service for secure authentication token storage
/// Uses FlutterSecureStorage on mobile, SharedPreferences on web
class AuthService {
  static _StorageBackend? _backend;

  /// Get the appropriate storage backend for the platform
  static _StorageBackend get _storage {
    if (_backend != null) return _backend!;

    if (kIsWeb) {
      // Use SharedPreferences on web (works without HTTPS)
      _backend = _WebStorageBackend();
    } else {
      // Use secure storage on mobile
      _backend = _SecureStorageBackend(
        const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        ),
      );
    }
    return _backend!;
  }

  // Storage keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _accountIdKey = 'account_id';
  static const _emailKey = 'email';
  static const _displayNameKey = 'display_name';
  static const _currentGroupKey = 'current_group_id';
  static const _adminTokenKeyPrefix = 'admin_token_';
  static const _userIdKeyPrefix = 'user_id_';
  static const _displayNameKeyPrefix = 'display_name_';
  static const _groupNameKeyPrefix = 'group_name_';
  static const _groupsListKey = 'groups_list';

  /// Debug method to inspect storage (for development only)
  static Future<void> debugPrintStorage() async {
    debugPrint('DEBUG: === STORAGE INSPECTION ===');
    final storage = _storage;

    // Check specific keys
    final currentGroup = await storage.read('current_group_id');
    final groupsList = await storage.read('groups_list');

    debugPrint('DEBUG: current_group_id: $currentGroup');
    debugPrint('DEBUG: groups_list: $groupsList');

    if (groupsList != null && groupsList.isNotEmpty) {
      final groupIds = groupsList.split(',');
      for (final groupId in groupIds) {
        final token = await storage.read('session_token_$groupId');
        final userId = await storage.read('user_id_$groupId');
        final displayName = await storage.read('display_name_$groupId');
        debugPrint(
            'DEBUG: Group $groupId - token: ${token != null ? "present (${token.length} chars)" : "null"}, userId: $userId, displayName: $displayName');
      }
    }

    // Also show all auth keys in localStorage
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        final authKeys = allKeys.where((key) => key.startsWith('auth_'));
        if (authKeys.isNotEmpty) {
          debugPrint('DEBUG: === ALL LOCALSTORAGE AUTH KEYS ===');
          for (final key in authKeys) {
            final value = prefs.get(key);
            final valueStr = value?.toString() ?? 'null';
            final truncated = valueStr.length > 50
                ? '${valueStr.substring(0, 50)}...'
                : valueStr;
            debugPrint('DEBUG: $key: $truncated');
          }
          debugPrint('DEBUG: === END ALL LOCALSTORAGE AUTH KEYS ===');
        }
      } catch (e) {
        debugPrint('DEBUG: Could not inspect localStorage: $e');
      }
    }
    debugPrint('DEBUG: === END STORAGE INSPECTION ===');
  }

  // ============= JWT Token Management =============

  /// Save JWT tokens from login/register response
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_refreshTokenKey, refreshToken);
  }

  /// Get current access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(_accessTokenKey);
  }

  /// Get current refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(_refreshTokenKey);
  }

  /// Save account info from login/register
  static Future<void> saveAccountInfo({
    required String accountId,
    required String email,
    required String displayName,
  }) async {
    await _storage.write(_accountIdKey, accountId);
    await _storage.write(_emailKey, email);
    await _storage.write(_displayNameKey, displayName);
  }

  /// Get account ID
  static Future<String?> getAccountId() async {
    return await _storage.read(_accountIdKey);
  }

  /// Get account email
  static Future<String?> getEmail() async {
    return await _storage.read(_emailKey);
  }

  /// Get account display name
  static Future<String?> getAccountDisplayName() async {
    return await _storage.read(_displayNameKey);
  }

  /// Save group membership info
  static Future<void> saveGroupMembership({
    required String groupId,
    required String userId,
    required String displayName,
    String? groupName,
  }) async {
    await _storage.write('$_userIdKeyPrefix$groupId', userId);
    await _storage.write('$_displayNameKeyPrefix$groupId', displayName);
    if (groupName != null) {
      await _storage.write('$_groupNameKeyPrefix$groupId', groupName);
    }
    await _storage.write(_currentGroupKey, groupId);

    // Add to groups list
    await _addToGroupsList(groupId);
  }

  /// Legacy compatibility: save session (delegates to new methods)
  static Future<void> saveSession({
    required String groupId,
    required String token,
    required String oderId,
    required String displayName,
    String? groupName,
  }) async {
    await saveGroupMembership(
      groupId: groupId,
      userId: oderId,
      displayName: displayName,
      groupName: groupName,
    );
  }

  /// Get access token (replaces old getToken)
  static Future<String?> getToken(String groupId) async {
    // JWT tokens are global, not per-group
    return await getAccessToken();
  }

  /// Get current active group ID
  static Future<String?> getCurrentGroupId() async {
    return await _storage.read(_currentGroupKey);
  }

  /// Set current active group
  static Future<void> setCurrentGroup(String groupId) async {
    await _storage.write(_currentGroupKey, groupId);
  }

  /// Get user ID for a group
  static Future<String?> getUserId(String groupId) async {
    return await _storage.read('$_userIdKeyPrefix$groupId');
  }

  /// Get display name for a group
  static Future<String?> getDisplayName(String groupId) async {
    return await _storage.read('$_displayNameKeyPrefix$groupId');
  }

  /// Get group name for a group
  static Future<String?> getGroupName(String groupId) async {
    return await _storage.read('$_groupNameKeyPrefix$groupId');
  }

  /// Save group name for a group
  static Future<void> saveGroupName(String groupId, String groupName) async {
    await _storage.write('$_groupNameKeyPrefix$groupId', groupName);
  }

  /// Clear session for a group
  static Future<void> clearSession(String groupId) async {
    await _storage.delete('$_userIdKeyPrefix$groupId');
    await _storage.delete('$_displayNameKeyPrefix$groupId');
    await _storage.delete('$_groupNameKeyPrefix$groupId');
    await _storage.delete('$_adminTokenKeyPrefix$groupId');

    // Remove from groups list
    await _removeFromGroupsList(groupId);

    // If this was the current group, clear it
    final currentGroup = await getCurrentGroupId();
    if (currentGroup == groupId) {
      final groups = await getGroupsList();
      if (groups.isNotEmpty) {
        await setCurrentGroup(groups.first);
      } else {
        await _storage.delete(_currentGroupKey);
      }
    }
  }

  /// Clear all sessions (logout from all groups)
  static Future<void> clearAllSessions() async {
    await _storage.deleteAll();
  }

  // ============= Admin Token Management =============

  /// Save admin token for a group
  static Future<void> saveAdminToken(String groupId, String adminToken) async {
    await _storage.write('$_adminTokenKeyPrefix$groupId', adminToken);
  }

  /// Get admin token for a group
  static Future<String?> getAdminToken(String groupId) async {
    return await _storage.read('$_adminTokenKeyPrefix$groupId');
  }

  /// Check if user is admin for a group
  static Future<bool> isAdmin(String groupId) async {
    final token = await getAdminToken(groupId);
    return token != null && token.isNotEmpty;
  }

  // ============= Multi-Group Support =============

  /// Get list of all joined groups
  static Future<List<String>> getGroupsList() async {
    final data = await _storage.read(_groupsListKey);
    if (data == null || data.isEmpty) return [];
    return data.split(',');
  }

  /// Add group to the list
  static Future<void> _addToGroupsList(String groupId) async {
    final groups = await getGroupsList();
    if (!groups.contains(groupId)) {
      groups.add(groupId);
      await _storage.write(_groupsListKey, groups.join(','));
    }
  }

  /// Remove group from the list
  static Future<void> _removeFromGroupsList(String groupId) async {
    final groups = await getGroupsList();
    groups.remove(groupId);
    await _storage.write(_groupsListKey, groups.join(','));
  }

  // ============= Convenience Methods =============

  /// Check if user has any active session
  static Future<bool> hasActiveSession() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Get current session info
  static Future<Map<String, String?>> getCurrentSessionInfo() async {
    final groupId = await getCurrentGroupId();
    final accessToken = await getAccessToken();

    if (groupId == null) {
      return {
        'groupId': null,
        'token': accessToken,
        'userId': null,
        'displayName': null,
      };
    }

    return {
      'groupId': groupId,
      'token': accessToken,
      'userId': await getUserId(groupId),
      'displayName': await getDisplayName(groupId),
    };
  }

  /// Refresh the access token using the refresh token
  static Future<Map<String, dynamic>?> refreshSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    final api = ApiClient();
    try {
      final response = await api.post(
        '/api/auth/refresh',
        {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        if (newAccessToken != null && newRefreshToken != null) {
          await saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
        }
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Helper to auto-refresh session after any authenticated API action
  static Future<void> autoRefreshSession() async {
    await refreshSession();
  }

  // ============= Instance Methods for Provider =============

  /// Get all groups with their info (for multi-group provider)
  Future<List<GroupInfo>> getAllGroups() async {
    final groupIds = await getGroupsList();
    final groups = <GroupInfo>[];

    for (final groupId in groupIds) {
      final displayName = await getDisplayName(groupId);
      groups.add(GroupInfo(
        groupId: groupId,
        groupName: displayName ?? 'Unknown Group',
      ));
    }

    return groups;
  }

  /// Remove a group (instance method)
  Future<void> removeGroup(String groupId) async {
    await clearSession(groupId);
  }
}

/// Basic group info for multi-group support
class GroupInfo {
  final String groupId;
  final String groupName;
  final String? inviteCode;

  const GroupInfo({
    required this.groupId,
    required this.groupName,
    this.inviteCode,
  });
}
