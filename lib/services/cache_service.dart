import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';

/// Service for local caching and offline support
class CacheService {
  static const String _questionCacheKey = 'cached_question';
  static const String _groupInfoCacheKey = 'cached_group_info_';
  static const String _membersCacheKey = 'cached_members_';
  static const String _lastSyncKey = 'last_sync_';

  // ============= Connectivity =============

  /// Check if device has internet connection
  static Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Listen to connectivity changes
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }

  // ============= Question Cache =============

  /// Cache today's question
  static Future<void> cacheQuestion(String groupId, DailyQuestion question) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_questionCacheKey}_$groupId';
    await prefs.setString(key, jsonEncode(question.toJson()));
    await _updateLastSync(groupId, 'question');
  }

  /// Get cached question
  static Future<DailyQuestion?> getCachedQuestion(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_questionCacheKey}_$groupId';
    final data = prefs.getString(key);
    
    if (data != null) {
      try {
        return DailyQuestion.fromJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clear cached question
  static Future<void> clearQuestionCache(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_questionCacheKey}_$groupId';
    await prefs.remove(key);
  }

  // ============= Group Info Cache =============

  /// Cache group info
  static Future<void> cacheGroupInfo(Group group) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_groupInfoCacheKey${group.groupId}';
    await prefs.setString(key, jsonEncode(group.toJson()));
    await _updateLastSync(group.groupId, 'group');
  }

  /// Get cached group info
  static Future<Group?> getCachedGroupInfo(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_groupInfoCacheKey$groupId';
    final data = prefs.getString(key);
    
    if (data != null) {
      try {
        return Group.fromJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ============= Members Cache =============

  /// Cache group members
  static Future<void> cacheMembers(String groupId, List<GroupMember> members) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_membersCacheKey$groupId';
    final data = members.map((m) => m.toJson()).toList();
    await prefs.setString(key, jsonEncode(data));
    await _updateLastSync(groupId, 'members');
  }

  /// Get cached members
  static Future<List<GroupMember>?> getCachedMembers(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_membersCacheKey$groupId';
    final data = prefs.getString(key);
    
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        return list.map((m) => GroupMember.fromJson(m as Map<String, dynamic>)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ============= Sync Tracking =============

  /// Update last sync timestamp
  static Future<void> _updateLastSync(String groupId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_lastSyncKey${groupId}_$type';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime(String groupId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_lastSyncKey${groupId}_$type';
    final timestamp = prefs.getInt(key);
    
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Check if cache is stale (older than specified duration)
  static Future<bool> isCacheStale(String groupId, String type, Duration maxAge) async {
    final lastSync = await getLastSyncTime(groupId, type);
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > maxAge;
  }

  // ============= Clear Cache =============

  /// Clear all cache for a group
  static Future<void> clearGroupCache(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_questionCacheKey}_$groupId');
    await prefs.remove('$_groupInfoCacheKey$groupId');
    await prefs.remove('$_membersCacheKey$groupId');
    await prefs.remove('$_lastSyncKey${groupId}_question');
    await prefs.remove('$_lastSyncKey${groupId}_group');
    await prefs.remove('$_lastSyncKey${groupId}_members');
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_questionCacheKey) ||
          key.startsWith(_groupInfoCacheKey) ||
          key.startsWith(_membersCacheKey) ||
          key.startsWith(_lastSyncKey)) {
        await prefs.remove(key);
      }
    }
  }
}
