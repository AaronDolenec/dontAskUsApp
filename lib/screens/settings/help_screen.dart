import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Help & Support screen with FAQ and app information
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.help),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Welcome to dontAskUs!',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'dontAskUs is a group-based daily question platform. '
                    'Answer fun questions with your friends and see how others respond!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Section
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          const _FAQItem(
            question: 'How do I join a group?',
            answer:
                'To join a group, you need an invite code from someone already in the group. '
                'Enter the 6-character code on the join screen and choose your display name and avatar color.',
          ),

          const _FAQItem(
            question: 'How do streaks work?',
            answer:
                'Your streak increases each day you answer the daily question. '
                'If you miss a day, your streak resets to zero. '
                'Try to maintain your streak to climb the leaderboard!',
          ),

          const _FAQItem(
            question: 'What are the different question types?',
            answer: 'There are several question types:\n\n'
                '• Binary Vote: Choose between two options (Yes/No, A/B)\n'
                '• Single Choice: Pick one answer from multiple options\n'
                '• Free Text: Write your own response\n'
                '• Member Choice: Vote for a group member\n'
                '• Duo Choice: Select two group members',
          ),

          const _FAQItem(
            question: 'Can I be in multiple groups?',
            answer:
                'Yes! You can join multiple groups with different invite codes. '
                'Use the "Switch Groups" option in Settings to change between them, '
                'or "Join Another Group" to add a new one.',
          ),

          const _FAQItem(
            question: 'How do I become an admin?',
            answer: 'You become an admin by creating a new group. '
                'Admins can create daily questions, manage question sets, '
                'and see the admin token for their group.',
          ),

          const _FAQItem(
            question: 'When does the daily question reset?',
            answer: 'The daily question resets at midnight (server time). '
                'Make sure to answer before then to keep your streak!',
          ),

          const _FAQItem(
            question: 'Can I change my vote after submitting?',
            answer: 'No, once you submit your answer, it cannot be changed. '
                'Make sure you\'re happy with your choice before submitting!',
          ),

          const _FAQItem(
            question: 'How do I invite others to my group?',
            answer: 'Go to Settings and look at the Group Info section. '
                'You can share the invite code directly, show a QR code, '
                'or use the Share button to send it via other apps.',
          ),

          const SizedBox(height: 24),

          // Contact Section
          Text(
            'Need More Help?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help with any issues'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // In a real app, this would open email or support page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support email: support@dontaskus.app'),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// A single FAQ item with expandable answer
class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
