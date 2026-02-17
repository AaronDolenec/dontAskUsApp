import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/app_colors.dart';
import '../../widgets/widgets.dart';
import '../admin/create_question_screen.dart';
import '../profile/profile_screen.dart';

/// Home screen displaying today's question
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  dynamic _selectedAnswer;
  final List<String> _selectedMultipleAnswers = [];
  final _textAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.hasGroup) {
        // Fetch question + connect WebSocket + start polling
        ref.read(questionProvider.notifier).fetchTodaysQuestion();
        ref.read(questionProvider.notifier).connectWebSocket();
        ref.read(questionProvider.notifier).startPolling();
      }
    });
  }

  @override
  void dispose() {
    ref.read(questionProvider.notifier).stopPolling();
    ref.read(questionProvider.notifier).disconnectWebSocket();
    _textAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref
        .read(questionProvider.notifier)
        .fetchTodaysQuestion(forceRefresh: true);
  }

  Future<void> _submitAnswer(DailyQuestion question) async {
    if (question.questionType == QuestionType.freeText) {
      if (_textAnswerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an answer')),
        );
        return;
      }
      await ref.read(questionProvider.notifier).submitAnswer(
            null,
            textAnswer: _textAnswerController.text.trim(),
          );
    } else if (question.allowMultiple) {
      if (_selectedMultipleAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one option')),
        );
        return;
      }
      await ref
          .read(questionProvider.notifier)
          .submitAnswer(_selectedMultipleAnswers);
    } else {
      if (_selectedAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an option')),
        );
        return;
      }
      await ref.read(questionProvider.notifier).submitAnswer(_selectedAnswer);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.substring(0, name.length >= 2 ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionProvider);
    final authState = ref.watch(authProvider);
    final userStreak = ref.watch(userStreakProvider);

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('dontAskUs'),
        leading: user != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: AvatarCircle(
                    colorHex: user.colorAvatar,
                    initials: _getInitials(user.displayName),
                    avatarUrl: user.avatarUrl,
                    size: 36,
                  ),
                ),
              )
            : null,
        actions: [
          if (authState.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateQuestionScreen(),
                  ),
                );
              },
              tooltip: 'Create Question',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Streak Display
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: StreakDisplay(
                  streak: userStreak,
                  longestStreak: questionState.question?.longestStreak ??
                      authState.user?.longestAnswerStreak,
                ),
              ),

              // Question Content
              if (questionState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: QuestionCardSkeleton(),
                )
              else if (questionState.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorDisplay(
                    message: questionState.error!,
                    onRetry: _handleRefresh,
                  ),
                )
              else if (questionState.question == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: NoQuestionDisplay(
                    isAdmin: authState.isAdmin,
                    onCreateQuestion: () {
                      // TODO: Navigate to create question screen
                    },
                  ),
                )
              else
                _buildQuestionContent(questionState.question!),

              const SizedBox(height: 100), // Bottom padding for scroll
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent(DailyQuestion question) {
    return QuestionCard(
      question: question,
      votingWidget: question.hasUserVoted ? null : _buildVotingWidget(question),
      resultsWidget:
          question.hasUserVoted ? _buildResultsWidget(question) : null,
    );
  }

  Widget _buildVotingWidget(DailyQuestion question) {
    final questionState = ref.watch(questionProvider);
    final isSubmitting = questionState.isSubmitting;

    switch (question.questionType) {
      case QuestionType.freeText:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textAnswerController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your answer here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : () => _submitAnswer(question),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Answer'),
            ),
          ],
        );

      default:
        // Single or multiple choice
        final options = question.options ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final color = AppColors.getVoteColor(index);

              if (question.allowMultiple) {
                final isSelected = _selectedMultipleAnswers.contains(option);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VoteOptionCard(
                    option: option,
                    isSelected: isSelected,
                    color: color,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMultipleAnswers.remove(option);
                        } else {
                          _selectedMultipleAnswers.add(option);
                        }
                      });
                    },
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VoteOptionCard(
                    option: option,
                    isSelected: _selectedAnswer == option,
                    color: color,
                    onTap: () {
                      setState(() {
                        _selectedAnswer = option;
                      });
                    },
                  ),
                );
              }
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isSubmitting ? null : () => _submitAnswer(question),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      question.allowMultiple ? 'Submit Votes' : 'Submit Vote'),
            ),
          ],
        );
    }
  }

  Widget _buildResultsWidget(DailyQuestion question) {
    final options = question.options ?? [];
    final winningOption = question.winningOption;

    if (question.questionType == QuestionType.freeText) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  'Your Answer',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.userTextAnswer ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final voteCount = question.optionCounts?[option] ?? 0;
        final color = AppColors.getVoteColor(index);
        final isWinner = option == winningOption;
        final isUserVote = question.userVoteList?.contains(option) ??
            question.userVoteString == option;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VoteOptionCard(
            option: option,
            voteCount: voteCount,
            totalVotes: question.totalVotes,
            isSelected: isUserVote,
            showResults: true,
            isWinner: isWinner,
            color: color,
          ),
        );
      }).toList(),
    );
  }
}
