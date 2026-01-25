import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Screen displaying question history
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(paginatedHistoryProvider);
      if (state.questions.isEmpty && !state.isLoading) {
        ref.read(paginatedHistoryProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedHistoryProvider.notifier).loadMore();
    }
  }

  bool _showLongLoading = false;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(paginatedHistoryProvider);

    // Show a message if loading takes longer than 3 seconds
    if (historyState.isLoading &&
        historyState.questions.isEmpty &&
        !_showLongLoading) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted &&
            historyState.isLoading &&
            historyState.questions.isEmpty) {
          setState(() {
            _showLongLoading = true;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _buildBody(historyState),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state.isLoading && state.questions.isEmpty) {
      if (_showLongLoading) {
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HistoryListSkeleton(),
            SizedBox(height: 32),
            Text(
              'Still loading... Please check your connection or try again later.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      return const HistoryListSkeleton();
    }

    if (state.error != null && state.questions.isEmpty) {
      return ErrorDisplay(
        message: 'Failed to load history',
        details: state.error,
        onRetry: () =>
            ref.read(paginatedHistoryProvider.notifier).loadInitial(),
      );
    }

    if (state.questions.isEmpty) {
      return const EmptyStateDisplay(
        title: 'History Coming Soon',
        subtitle:
            'Question history is not yet available.\nCheck back in a future update!',
        icon: Icons.hourglass_empty,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(paginatedHistoryProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.questions.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.questions.length) {
            // Loading indicator at the bottom
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final question = state.questions[index];
          return QuestionHistoryCard(
            question: question,
            onTap: () {
              // TODO: Navigate to question detail
            },
          );
        },
      ),
    );
  }
}
