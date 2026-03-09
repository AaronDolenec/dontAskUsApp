import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/share_service.dart';

/// Help & Support screen with FAQ and app information
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _supportEmail = 'admin@everblue.work';

  Future<void> _openSupportEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'dontAskUs Support Request',
      },
    );

    final launched = await launchUrl(uri);
    if (launched || !context.mounted) return;

    final copied = await ShareService.copyText(_supportEmail);
    if (!context.mounted) return;
    ShareService.showCopyResult(context, copied, _supportEmail);
  }

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
                          l10n.helpWelcomeTitle,
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
                    l10n.helpWelcomeDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.helpQuickStart,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // How to use section
          Text(
            l10n.helpHowToUse,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          _HelpStepItem(
            number: '1',
            title: l10n.helpStep1Title,
            description: l10n.helpStep1Desc,
          ),
          _HelpStepItem(
            number: '2',
            title: l10n.helpStep2Title,
            description: l10n.helpStep2Desc,
          ),
          _HelpStepItem(
            number: '3',
            title: l10n.helpStep3Title,
            description: l10n.helpStep3Desc,
          ),
          _HelpStepItem(
            number: '4',
            title: l10n.helpStep4Title,
            description: l10n.helpStep4Desc,
          ),

          const SizedBox(height: 24),

          // Feature highlights
          Text(
            l10n.helpFeatureHighlights,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.quiz_outlined,
            title: l10n.helpFeatureTypesTitle,
            subtitle: l10n.helpFeatureTypesDesc,
          ),
          _FeatureTile(
            icon: Icons.notifications_outlined,
            title: l10n.helpFeatureNotifTitle,
            subtitle: l10n.helpFeatureNotifDesc,
          ),
          _FeatureTile(
            icon: Icons.group_outlined,
            title: l10n.helpFeatureGroupsTitle,
            subtitle: l10n.helpFeatureGroupsDesc,
          ),
          _FeatureTile(
            icon: Icons.bar_chart_outlined,
            title: l10n.helpFeatureLeaderboardTitle,
            subtitle: l10n.helpFeatureLeaderboardDesc,
          ),

          const SizedBox(height: 24),

          // FAQ Section
          Text(
            l10n.helpFaqTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          _FAQItem(
            question: l10n.helpFaqJoinQuestion,
            answer: l10n.helpFaqJoinAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqStreakQuestion,
            answer: l10n.helpFaqStreakAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqTypesQuestion,
            answer: l10n.helpFaqTypesAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqMultiGroupQuestion,
            answer: l10n.helpFaqMultiGroupAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqAdminQuestion,
            answer: l10n.helpFaqAdminAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqResetQuestion,
            answer: l10n.helpFaqResetAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqRevoteQuestion,
            answer: l10n.helpFaqRevoteAnswer,
          ),

          _FAQItem(
            question: l10n.helpFaqInviteQuestion,
            answer: l10n.helpFaqInviteAnswer,
          ),

          const SizedBox(height: 24),

          // Contact Section
          Text(
            l10n.helpNeedMore,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _supportEmail,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await ShareService.copyText(_supportEmail);
                          if (!context.mounted) return;
                          ShareService.showCopyResult(
                              context, ok, _supportEmail);
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(l10n.copyCode),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => _openSupportEmail(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(l10n.helpEmailButton),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.helpSupportHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _HelpStepItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _HelpStepItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
