import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

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
  final response = await apiClient.get('/api/question-sets');

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
  final response =
      await apiClient.get('/api/groups/${authState.groupId}/question-sets');

  if (response.statusCode == 200) {
    return _parseQuestionSetsResponse(
      response.body,
      listKey: 'question_sets',
    );
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Helper to ensure we have both groupId and adminToken
  Future<_GroupAndAdmin?> _requireGroupAndAdmin() async {
    final authState = ref.read(authProvider);
    if (!authState.hasGroup || authState.groupId == null) return null;

    final adminToken = await ref.read(adminTokenProvider.future);
    if (adminToken == null) return null;

    return _GroupAndAdmin(
      groupId: authState.groupId!,
      adminToken: adminToken,
    );
  }

  Future<void> _assignSet(QuestionSet set) async {
    try {
      final params = await _requireGroupAndAdmin();
      if (params == null) return;

      final apiClient = ref.read(apiClientProvider);
      // API uses POST with question_set_ids array
      await apiClient.post(
        '/api/groups/${params.groupId}/question-sets',
        {
          'question_set_ids': [set.setId],
          'replace': false,
        },
        adminToken: params.adminToken,
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
      final params = await _requireGroupAndAdmin();
      if (params == null) return;

      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(
        '/api/groups/${params.groupId}/question-sets/${set.setId}',
        adminToken: params.adminToken,
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableSetsTab(),
          _buildGroupSetsTab(),
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
}

class _GroupAndAdmin {
  final String groupId;
  final String adminToken;

  const _GroupAndAdmin({
    required this.groupId,
    required this.adminToken,
  });
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
