import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure authentication token storage
class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const _tokenKeyPrefix = 'session_token_';
  static const _currentGroupKey = 'current_group_id';
  static const _adminTokenKeyPrefix = 'admin_token_';
  static const _userIdKeyPrefix = 'user_id_';
  static const _displayNameKeyPrefix = 'display_name_';
  static const _groupsListKey = 'groups_list';

  // ============= Session Token Management =============

  /// Save session for a group
  static Future<void> saveSession({
    required String groupId,
    required String token,
    required String oderId,
    required String displayName,
  }) async {
    await _storage.write(key: '$_tokenKeyPrefix$groupId', value: token);
    await _storage.write(key: '$_userIdKeyPrefix$groupId', value: oderId);
    await _storage.write(
        key: '$_displayNameKeyPrefix$groupId', value: displayName);
    await _storage.write(key: _currentGroupKey, value: groupId);

    // Add to groups list
    await _addToGroupsList(groupId);
  }

  /// Get session token for a group
  static Future<String?> getToken(String groupId) async {
    return await _storage.read(key: '$_tokenKeyPrefix$groupId');
  }

  /// Get current active group ID
  static Future<String?> getCurrentGroupId() async {
    return await _storage.read(key: _currentGroupKey);
  }

  /// Set current active group
  static Future<void> setCurrentGroup(String groupId) async {
    await _storage.write(key: _currentGroupKey, value: groupId);
  }

  /// Get user ID for a group
  static Future<String?> getUserId(String groupId) async {
    return await _storage.read(key: '$_userIdKeyPrefix$groupId');
  }

  /// Get display name for a group
  static Future<String?> getDisplayName(String groupId) async {
    return await _storage.read(key: '$_displayNameKeyPrefix$groupId');
  }

  /// Clear session for a group
  static Future<void> clearSession(String groupId) async {
    await _storage.delete(key: '$_tokenKeyPrefix$groupId');
    await _storage.delete(key: '$_userIdKeyPrefix$groupId');
    await _storage.delete(key: '$_displayNameKeyPrefix$groupId');
    await _storage.delete(key: '$_adminTokenKeyPrefix$groupId');

    // Remove from groups list
    await _removeFromGroupsList(groupId);

    // If this was the current group, clear it
    final currentGroup = await getCurrentGroupId();
    if (currentGroup == groupId) {
      final groups = await getGroupsList();
      if (groups.isNotEmpty) {
        await setCurrentGroup(groups.first);
      } else {
        await _storage.delete(key: _currentGroupKey);
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
    await _storage.write(
        key: '$_adminTokenKeyPrefix$groupId', value: adminToken);
  }

  /// Get admin token for a group
  static Future<String?> getAdminToken(String groupId) async {
    return await _storage.read(key: '$_adminTokenKeyPrefix$groupId');
  }

  /// Check if user is admin for a group
  static Future<bool> isAdmin(String groupId) async {
    final token = await getAdminToken(groupId);
    return token != null && token.isNotEmpty;
  }

  // ============= Multi-Group Support =============

  /// Get list of all joined groups
  static Future<List<String>> getGroupsList() async {
    final data = await _storage.read(key: _groupsListKey);
    if (data == null || data.isEmpty) return [];
    return data.split(',');
  }

  /// Add group to the list
  static Future<void> _addToGroupsList(String groupId) async {
    final groups = await getGroupsList();
    if (!groups.contains(groupId)) {
      groups.add(groupId);
      await _storage.write(key: _groupsListKey, value: groups.join(','));
    }
  }

  /// Remove group from the list
  static Future<void> _removeFromGroupsList(String groupId) async {
    final groups = await getGroupsList();
    groups.remove(groupId);
    await _storage.write(key: _groupsListKey, value: groups.join(','));
  }

  // ============= Convenience Methods =============

  /// Check if user has any active session
  static Future<bool> hasActiveSession() async {
    final groupId = await getCurrentGroupId();
    if (groupId == null) return false;
    final token = await getToken(groupId);
    return token != null && token.isNotEmpty;
  }

  /// Get current session info
  static Future<Map<String, String?>> getCurrentSessionInfo() async {
    final groupId = await getCurrentGroupId();
    if (groupId == null) {
      return {
        'groupId': null,
        'token': null,
        'userId': null,
        'displayName': null,
      };
    }

    return {
      'groupId': groupId,
      'token': await getToken(groupId),
      'userId': await getUserId(groupId),
      'displayName': await getDisplayName(groupId),
    };
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
