import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_question.dart';
import '../../models/question_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/error_display.dart';
import '../../widgets/question_card.dart';
import '../../widgets/vote_option_card.dart';
import '../profile/profile_screen.dart';
import '../groups/groups_screen.dart';

/// Home screen displaying today's question
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  dynamic _selectedAnswer;
  final List<String> _selectedMultipleAnswers = [];
  final _textAnswerController = TextEditingController();
  bool _showStreakCelebration = false;
  int _celebrationStreak = 0;
  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
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
    _celebrationController.dispose();
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
    final oldStreak = ref.read(userStreakProvider);
    bool success = false;

    if (question.questionType == QuestionType.freeText) {
      if (_textAnswerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an answer')),
        );
        return;
      }
      success = await ref.read(questionProvider.notifier).submitAnswer(
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
      success = await ref
          .read(questionProvider.notifier)
          .submitAnswer(_selectedMultipleAnswers);
    } else {
      if (_selectedAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an option')),
        );
        return;
      }
      success = await ref
          .read(questionProvider.notifier)
          .submitAnswer(_selectedAnswer);
    }

    if (success && mounted) {
      final newStreak = ref.read(userStreakProvider);
      if (newStreak > oldStreak) {
        setState(() {
          _showStreakCelebration = true;
          _celebrationStreak = newStreak;
        });
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showStreakCelebration = false;
            });
          }
        });
      }
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
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const GroupsScreen()),
                (route) => false,
              );
            },
            tooltip: 'My Groups',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Streak Celebration
              if (_showStreakCelebration)
                AnimatedBuilder(
                  animation: _celebrationAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _celebrationAnimation.value.clamp(0.0, 1.0),
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF97316),
                          Color(0xFFF59E0B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Text(
                          '$_celebrationStreak day streak!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('🎉', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                  ),
                ),

              // Streak Display
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: StreakDisplay(
                  streak: userStreak,
                  longestStreak: ref.watch(longestStreakProvider),
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: NoQuestionDisplay(),
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
    final isFromToday = ref.watch(
      questionProvider.select((s) => s.isFromToday),
    );

    // Past question – always show results, never show voting
    if (!isFromToday) {
      return Column(
        children: [
          // Past-question banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No new question yet \u2013 here are the latest results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          QuestionCard(
            question: question,
            resultsWidget: _buildResultsWidget(question),
          ),
        ],
      );
    }

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

    // Build list of options with their vote counts, filter out zero votes,
    // and sort by vote count descending
    final allOptions = question.options ?? [];
    final optionsWithVotes = <_OptionResult>[];
    for (final option in allOptions) {
      final count = question.optionCounts?[option] ?? 0;
      if (count > 0) {
        optionsWithVotes.add(_OptionResult(
          option: option,
          voteCount: count,
          isWinner: option == winningOption,
          isUserVote: question.userVoteList?.contains(option) ??
              question.userVoteString == option,
        ));
      }
    }
    optionsWithVotes.sort((a, b) => b.voteCount.compareTo(a.voteCount));

    if (optionsWithVotes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No votes yet',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Results',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...optionsWithVotes.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          final color = AppColors.getVoteColor(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: VoteOptionCard(
              option: result.option,
              voteCount: result.voteCount,
              totalVotes: question.totalVotes,
              isSelected: result.isUserVote,
              showResults: true,
              isWinner: result.isWinner,
              color: color,
            ),
          );
        }),
      ],
    );
  }
}

/// Helper class to hold option result data for sorting
class _OptionResult {
  final String option;
  final int voteCount;
  final bool isWinner;
  final bool isUserVote;

  const _OptionResult({
    required this.option,
    required this.voteCount,
    required this.isWinner,
    required this.isUserVote,
  });
}
