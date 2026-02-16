import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

/// Provider for current group info
final groupInfoProvider = FutureProvider<Group?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return null;

  // Try cache first
  final cached = await CacheService.getCachedGroupInfo(auth.groupId!);
  final isStale = await CacheService.isCacheStale(
    auth.groupId!,
    'group',
    const Duration(hours: 1),
  );

  if (cached != null && !isStale) {
    return cached;
  }

  // Fetch from API
  try {
    final token = await AuthService.getToken(auth.groupId!);
    final api = ref.read(apiClientProvider);
    final response =
        await api.get('/api/groups/${auth.groupId}/info', accessToken: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final group = Group.fromJson(data);

      // Cache the result
      await CacheService.cacheGroupInfo(group);

      // Also save group name for multi-group display
      await AuthService.saveGroupName(auth.groupId!, group.name);

      return group;
    }
  } catch (e) {
    // Return cached if available
    if (cached != null) return cached;
  }

  return null;
});

/// Provider for group preview (by invite code)
final groupPreviewProvider =
    FutureProvider.family<Group?, String>((ref, inviteCode) async {
  if (inviteCode.isEmpty) return null;

  try {
    final token = await AuthService.getAccessToken();
    final api = ref.read(apiClientProvider);
    final response =
        await api.get('/api/groups/$inviteCode', accessToken: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Group.fromJson(data);
    }
  } catch (_) {}

  return null;
});

/// Provider for group members
final groupMembersProvider = FutureProvider<List<GroupMember>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return [];

  // Try cache first
  final cached = await CacheService.getCachedMembers(auth.groupId!);
  final isStale = await CacheService.isCacheStale(
    auth.groupId!,
    'members',
    const Duration(minutes: 15),
  );

  if (cached != null && !isStale) {
    return cached;
  }

  // Fetch from API
  try {
    final token = await AuthService.getToken(auth.groupId!);
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/${auth.groupId}/members',
        accessToken: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List membersJson;
      if (data is Map<String, dynamic> && data.containsKey('members')) {
        membersJson = data['members'] as List? ?? [];
      } else if (data is List) {
        membersJson = data;
      } else {
        membersJson = [];
      }
      final members = membersJson
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();

      // Cache the result
      await CacheService.cacheMembers(auth.groupId!, members);

      return members;
    } else {
      // API error
    }
  } catch (e) {
    // Return cached if available
    if (cached != null) return cached;
  }

  return [];
});

/// Provider for group members sorted by streak
final membersByStreakProvider = Provider<List<GroupMember>>((ref) {
  final membersAsync = ref.watch(groupMembersProvider);
  return membersAsync.when(
    data: (members) {
      final sorted = List<GroupMember>.from(members);
      sorted.sort((a, b) => b.answerStreak.compareTo(a.answerStreak));
      return sorted;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for group members sorted by name
final membersByNameProvider = Provider<List<GroupMember>>((ref) {
  final membersAsync = ref.watch(groupMembersProvider);
  return membersAsync.when(
    data: (members) {
      final sorted = List<GroupMember>.from(members);
      sorted.sort((a, b) => a.displayName.compareTo(b.displayName));
      return sorted;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for group leaderboard (using dedicated leaderboard endpoint)
/// Returns members sorted by streak from the API
/// Provider for group leaderboard with live updates
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, List<GroupMember>>((ref) {
  return LeaderboardNotifier(ref);
});

class LeaderboardNotifier extends StateNotifier<List<GroupMember>> {
  final Ref _ref;
  WebSocketService? _wsService;

  LeaderboardNotifier(this._ref) : super([]) {
    _fetchLeaderboard();
    _connectWebSocket();
  }

  Future<void> _fetchLeaderboard() async {
    final auth = _ref.read(authProvider);
    if (auth.groupId == null) return;
    try {
      final token = await AuthService.getToken(auth.groupId!);
      if (token == null) return;
      final api = _ref.read(apiClientProvider);
      final response = await api.get(
        '/api/groups/${auth.groupId}/leaderboard',
        accessToken: token,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          state = data
              .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // Fall back to members sorted by streak
      state = _ref.read(membersByStreakProvider);
    }
  }

  void _connectWebSocket() {
    final auth = _ref.read(authProvider);
    if (auth.groupId == null) return;
    _wsService?.dispose();
    _wsService = WebSocketService(
      groupId: auth.groupId!,
      questionId: '', // Not needed for leaderboard
      onConnected: () {},
      onError: (error) {},
      onDisconnected: () {},
    );
    _wsService!.connect();
    _wsService!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic> &&
          data['type'] == 'leaderboard_update') {
        final membersJson = data['leaderboard'] as List? ?? [];
        final members = membersJson
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();
        state = members;
      }
    });
  }

  @override
  void dispose() {
    _wsService?.dispose();
    super.dispose();
  }
}

/// Provider for group question sets
final groupQuestionSetsProvider =
    FutureProvider<List<QuestionSet>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return [];
  try {
    final token = await AuthService.getToken(auth.groupId!);
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/${auth.groupId}/question-sets',
        accessToken: token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final setsJson = data['question_sets'] as List? ?? [];
      return setsJson
          .map((s) => QuestionSet.fromJson(s as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {}
  return [];
});

class GroupMembersWebSocket {
  WebSocketService? _wsService;
  final String groupId;
  final void Function(List<GroupMember>) onMembersUpdate;

  GroupMembersWebSocket({required this.groupId, required this.onMembersUpdate});

  void connect() {
    _wsService?.dispose();
    _wsService = WebSocketService(
      groupId: groupId,
      questionId: '', // Not needed for members
      onConnected: () {},
      onError: (error) {},
      onDisconnected: () {},
    );
    _wsService!.connect();
    _wsService!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic> && data['type'] == 'members_update') {
        final membersJson = data['members'] as List? ?? [];
        final members = membersJson
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();
        onMembersUpdate(members);
      }
    });
  }

  void disconnect() {
    _wsService?.dispose();
    _wsService = null;
  }
}
