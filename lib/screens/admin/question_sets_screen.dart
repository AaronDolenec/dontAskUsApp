import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/question_set.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_exception.dart';
import '../../utils/app_colors.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_shimmer.dart';
import 'private_question_set_screen.dart';

List<QuestionSet> _parseQuestionSetsResponse(
  String body, {
  String? listKey,
}) {
  final data = jsonDecode(body);

  if (data is Map && listKey != null && data[listKey] is List) {
    final setsList = data[listKey] as List;
    return setsList
        .map((json) => QuestionSet.fromJson(json as Map<String, dynamic>))
        .toList();
  } else if (data is List) {
    return data
        .map((json) => QuestionSet.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  return [];
}

// Provider for fetching question sets
final questionSetsProvider =
    FutureProvider.autoDispose<List<QuestionSet>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final accessToken = await ref.read(accessTokenProvider.future);
  final response =
      await apiClient.get('/api/question-sets', accessToken: accessToken);

  if (response.statusCode == 200) {
    return _parseQuestionSetsResponse(
      response.body,
      listKey: 'sets',
    );
  }
  return [];
});

// Provider for group's assigned sets
final groupQuestionSetsProvider =
    FutureProvider.autoDispose<List<QuestionSet>>((ref) async {
  final authState = ref.read(authProvider);
  if (!authState.hasGroup || authState.groupId == null) return [];

  final apiClient = ref.read(apiClientProvider);
  final accessToken = await ref.read(accessTokenProvider.future);
  final response = await apiClient.get(
      '/api/groups/${authState.groupId}/question-sets',
      accessToken: accessToken);

  if (response.statusCode == 200) {
    return _parseQuestionSetsResponse(
      response.body,
      listKey: 'question_sets',
    );
  }
  return [];
});

/// Provider for the group owner's private question sets
final myPrivateSetsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.read(authProvider);
  if (!authState.hasGroup || authState.groupId == null) return [];

  final apiClient = ref.read(apiClientProvider);
  final accessToken = await ref.read(accessTokenProvider.future);
  final response = await apiClient.get(
      '/api/groups/${authState.groupId}/question-sets/my',
      accessToken: accessToken);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is Map && data['sets'] is List) {
      return (data['sets'] as List).cast<Map<String, dynamic>>();
    }
  }
  return [];
});

class QuestionSetsScreen extends ConsumerStatefulWidget {
  const QuestionSetsScreen({super.key});

  @override
  ConsumerState<QuestionSetsScreen> createState() => _QuestionSetsScreenState();
}

class _QuestionSetsScreenState extends ConsumerState<QuestionSetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Helper to ensure we have groupId and access token
  Future<_GroupAndAuth?> _requireGroupAndAuth() async {
    final authState = ref.read(authProvider);
    if (!authState.hasGroup || authState.groupId == null) return null;

    final accessToken = await ref.read(accessTokenProvider.future);
    if (accessToken == null) return null;

    return _GroupAndAuth(
      groupId: authState.groupId!,
      accessToken: accessToken,
    );
  }

  Future<void> _assignSet(QuestionSet set) async {
    try {
      final params = await _requireGroupAndAuth();
      if (params == null) return;

      final apiClient = ref.read(apiClientProvider);
      // API uses POST with question_set_ids array
      await apiClient.post(
        '/api/groups/${params.groupId}/question-sets',
        {
          'question_set_ids': [set.setId],
          'replace': false,
        },
        accessToken: params.accessToken,
      );

      ref.invalidate(groupQuestionSetsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned "${set.name}" to your group'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unassignSet(QuestionSet set) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Question Set?'),
        content: Text('Remove "${set.name}" from your group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final params = await _requireGroupAndAuth();
      if (params == null) return;

      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(
        '/api/groups/${params.groupId}/question-sets/${set.setId}',
        accessToken: params.accessToken,
      );

      ref.invalidate(groupQuestionSetsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${set.name}" from your group'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Sets'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Group'),
            Tab(text: 'My Sets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableSetsTab(),
          _buildGroupSetsTab(),
          _buildMySetsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableSetsTab() {
    final setsAsync = ref.watch(questionSetsProvider);
    final groupSetsAsync = ref.watch(groupQuestionSetsProvider);

    return setsAsync.when(
      loading: () => const _QuestionSetListLoading(),
      error: (error, _) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.invalidate(questionSetsProvider),
      ),
      data: (sets) {
        final groupSets = groupSetsAsync.valueOrNull ?? [];
        final assignedIds = groupSets.map((s) => s.setId).toSet();

        if (sets.isEmpty) {
          return const _QuestionSetEmptyState(
            title: 'No question sets available',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(questionSetsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              final isAssigned = assignedIds.contains(set.setId);

              return _QuestionSetCard(
                set: set,
                isAssigned: isAssigned,
                onTap: isAssigned ? null : () => _assignSet(set),
                actionLabel: isAssigned ? 'Assigned' : 'Add to Group',
                actionIcon: isAssigned ? Icons.check : Icons.add,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupSetsTab() {
    final groupSetsAsync = ref.watch(groupQuestionSetsProvider);

    return groupSetsAsync.when(
      loading: () => const _QuestionSetListLoading(),
      error: (error, _) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.invalidate(groupQuestionSetsProvider),
      ),
      data: (sets) {
        if (sets.isEmpty) {
          return _QuestionSetEmptyState(
            title: 'No question sets assigned',
            showBrowseButton: true,
            onBrowsePressed: () => _tabController.animateTo(0),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupQuestionSetsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];

              return _QuestionSetCard(
                set: set,
                isAssigned: true,
                onTap: () => _unassignSet(set),
                actionLabel: 'Remove',
                actionIcon: Icons.remove_circle_outline,
                actionColor: Colors.red,
              );
            },
          ),
        );
      },
    );
  }

  // ── My Private Sets Tab ──────────────────────────────────────────

  Widget _buildMySetsTab() {
    final privateSetsAsync = ref.watch(myPrivateSetsProvider);

    return privateSetsAsync.when(
      loading: () => const _QuestionSetListLoading(),
      error: (error, _) {
        final msg = error.toString();
        // If 403, user is not the group creator
        if (msg.contains('403') || msg.contains('permission')) {
          return const _QuestionSetEmptyState(
            title: 'Only group creators can manage private sets',
          );
        }
        return ErrorDisplay(
          message: msg,
          onRetry: () => ref.invalidate(myPrivateSetsProvider),
        );
      },
      data: (sets) {
        return Column(
          children: [
            // Create button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createPrivateSet(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Question Set'),
                ),
              ),
            ),
            if (sets.isEmpty)
              const Expanded(
                child: _QuestionSetEmptyState(
                  title: 'No private sets yet',
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myPrivateSetsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sets.length,
                    itemBuilder: (context, index) {
                      final set = sets[index];
                      return _PrivateSetCard(
                        setData: set,
                        onEdit: () => _editPrivateSet(set),
                        onDelete: () => _deletePrivateSet(set),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _createPrivateSet() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PrivateQuestionSetScreen(),
      ),
    );
    if (result == true) {
      ref.invalidate(myPrivateSetsProvider);
      ref.invalidate(groupQuestionSetsProvider);
    }
  }

  Future<void> _editPrivateSet(Map<String, dynamic> setData) async {
    // Fetch full set details to get questions
    final params = await _requireGroupAndAuth();
    if (params == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final setId = setData['id'];
      final response = await api.get(
        '/api/groups/${params.groupId}/question-sets/$setId',
        accessToken: params.accessToken,
      );

      if (response.statusCode == 200) {
        final detail = jsonDecode(response.body) as Map<String, dynamic>;
        final templates = detail['templates'] as List? ?? [];
        final questions = templates
            .map((t) => <String, dynamic>{
                  'text': t['question_text'] ?? '',
                  'question_type': t['question_type'] ?? 'binary_vote',
                  if (t['options'] != null) 'options': t['options'],
                })
            .toList();

        if (!mounted) return;
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PrivateQuestionSetScreen(
              existingSetId: setId as int,
              existingName: setData['name'] as String?,
              existingDescription: detail['description'] as String?,
              existingQuestions: questions,
            ),
          ),
        );
        if (result == true) {
          ref.invalidate(myPrivateSetsProvider);
          ref.invalidate(groupQuestionSetsProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load set: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePrivateSet(Map<String, dynamic> setData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question Set?'),
        content: Text('Delete "${setData['name']}"? This cannot be undone.\n\n'
            'Note: Sets currently assigned to your group cannot be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final params = await _requireGroupAndAuth();
      if (params == null) return;

      final api = ref.read(apiClientProvider);
      final response = await api.delete(
        '/api/groups/${params.groupId}/question-sets/${setData['id']}',
        accessToken: params.accessToken,
      );

      if (response.statusCode == 200) {
        ref.invalidate(myPrivateSetsProvider);
        ref.invalidate(groupQuestionSetsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question set deleted')),
          );
        }
      } else {
        final exception = ApiException.fromResponse(response);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(exception.userFriendlyMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _GroupAndAuth {
  final String groupId;
  final String accessToken;

  const _GroupAndAuth({
    required this.groupId,
    required this.accessToken,
  });
}

class _PrivateSetCard extends StatelessWidget {
  final Map<String, dynamic> setData;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrivateSetCard({
    required this.setData,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = setData['name'] as String? ?? 'Unnamed';
    final questionCount = setData['question_count'] as int? ?? 0;
    final usageCount = setData['usage_count'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$questionCount questions · Used $usageCount times',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Private',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionSetCard extends StatelessWidget {
  final QuestionSet set;
  final bool isAssigned;
  final VoidCallback? onTap;
  final String actionLabel;
  final IconData actionIcon;
  final Color? actionColor;

  const _QuestionSetCard({
    required this.set,
    required this.isAssigned,
    required this.onTap,
    required this.actionLabel,
    required this.actionIcon,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (set.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          set.description!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: set.isPublic
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    set.isPublic ? 'Public' : 'Private',
                    style: TextStyle(
                      color: set.isPublic ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: actionColor ??
                        (isAssigned && onTap == null
                            ? Colors.grey
                            : AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionSetListLoading extends StatelessWidget {
  const _QuestionSetListLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) {
        return const LoadingShimmer(
          child: Card(
            margin: EdgeInsets.only(bottom: 12),
            child: SizedBox(height: 110),
          ),
        );
      },
    );
  }
}

class _QuestionSetEmptyState extends StatelessWidget {
  final String title;
  final bool showBrowseButton;
  final VoidCallback? onBrowsePressed;

  const _QuestionSetEmptyState({
    required this.title,
    this.showBrowseButton = false,
    this.onBrowsePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
          if (showBrowseButton) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBrowsePressed,
              child: const Text('Browse Available Sets'),
            ),
          ],
        ],
      ),
    );
  }
}
