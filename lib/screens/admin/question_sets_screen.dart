import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

// Provider for fetching question sets
final questionSetsProvider =
    FutureProvider.autoDispose<List<QuestionSet>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/question-sets');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is List) {
      return data
          .map((json) => QuestionSet.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }
  return [];
});

// Provider for group's assigned sets
final groupQuestionSetsProvider =
    FutureProvider.autoDispose<List<QuestionSet>>((ref) async {
  final authState = ref.read(authProvider);
  if (!authState.isAuthenticated || authState.groupId == null) return [];

  final apiClient = ref.read(apiClientProvider);
  final response =
      await apiClient.get('/groups/${authState.groupId}/question-sets');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is List) {
      return data
          .map((json) => QuestionSet.fromJson(json as Map<String, dynamic>))
          .toList();
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _assignSet(QuestionSet set) async {
    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated || authState.groupId == null) return;

      final adminToken = await ref.read(adminTokenProvider.future);

      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/groups/${authState.groupId}/question-sets/${set.setId}/assign',
        const {},
        adminToken: adminToken,
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
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated || authState.groupId == null) return;

      final adminToken = await ref.read(adminTokenProvider.future);

      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete(
        '/groups/${authState.groupId}/question-sets/${set.setId}',
        adminToken: adminToken,
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No question sets available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No question sets assigned',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Browse Available Sets'),
                ),
              ],
            ),
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
