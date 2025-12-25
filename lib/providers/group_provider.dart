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
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/${auth.groupId}/info');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final group = Group.fromJson(data);
      
      // Cache the result
      await CacheService.cacheGroupInfo(group);
      
      return group;
    }
  } catch (e) {
    // Return cached if available
    if (cached != null) return cached;
  }
  
  return null;
});

/// Provider for group preview (by invite code)
final groupPreviewProvider = FutureProvider.family<Group?, String>((ref, inviteCode) async {
  if (inviteCode.isEmpty) return null;
  
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/$inviteCode');
    
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
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/${auth.groupId}/members');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final membersJson = data['members'] as List;
      final members = membersJson
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();
      
      // Cache the result
      await CacheService.cacheMembers(auth.groupId!, members);
      
      return members;
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

/// Provider for group question sets
final groupQuestionSetsProvider = FutureProvider<List<QuestionSet>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.groupId == null) return [];
  
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/groups/${auth.groupId}/question-sets');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final setsJson = data['question_sets'] as List;
      return setsJson
          .map((s) => QuestionSet.fromJson(s as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {}
  
  return [];
});

/// Provider for public question sets
final publicQuestionSetsProvider = FutureProvider<List<QuestionSet>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/question-sets');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final setsJson = data['sets'] as List;
      return setsJson
          .map((s) => QuestionSet.fromJson(s as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {}
  
  return [];
});
