import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class VotingView extends StatefulWidget {
  final DailyQuestion question;
  final List<GroupMember> members;
  final Function(List<String>) onSubmit;
  final bool isSubmitting;

  const VotingView({
    super.key,
    required this.question,
    required this.members,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  State<VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends State<VotingView> {
  final Set<String> _selectedOptions = {};
  final TextEditingController _textController = TextEditingController();
  String? _selectedMember;
  String? _selectedMember2;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVotingOptions(),
        const SizedBox(height: 20),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildVotingOptions() {
    switch (widget.question.questionType) {
      case QuestionType.binaryVote:
        return _buildBinaryOptions();
      case QuestionType.singleChoice:
        return _buildSingleChoiceOptions();
      case QuestionType.freeText:
        return _buildFreeTextInput();
      case QuestionType.memberChoice:
        return _buildMemberChoiceOptions();
      case QuestionType.duoChoice:
        return _buildDuoChoiceOptions();
    }
  }

  Widget _buildBinaryOptions() {
    final options = widget.question.options ?? ['Yes', 'No'];
    return Row(
      children: options.map((option) {
        final isSelected = _selectedOptions.contains(option);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _BinaryOptionButton(
              label: option,
              isSelected: isSelected,
              onTap: () => _toggleOption(option),
              icon: option.toLowerCase() == 'yes'
                  ? Icons.thumb_up
                  : Icons.thumb_down,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleChoiceOptions() {
    final options = widget.question.options ?? [];
    return Column(
      children: options.map((option) {
        final isSelected = _selectedOptions.contains(option);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VoteOptionCard(
            option: option,
            isSelected: isSelected,
            onTap: () => _toggleOption(option),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFreeTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildMemberChoiceOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        final isSelected = _selectedMember == member.userId;
        return _MemberOptionCard(
          member: member,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedMember = member.userId;
            });
          },
        );
      },
    );
  }

  Widget _buildDuoChoiceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select first member:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildMemberDropdown(
          value: _selectedMember,
          onChanged: (value) => setState(() => _selectedMember = value),
          excludeId: _selectedMember2,
        ),
        const SizedBox(height: 16),
        Text(
          'Select second member:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildMemberDropdown(
          value: _selectedMember2,
          onChanged: (value) => setState(() => _selectedMember2 = value),
          excludeId: _selectedMember,
        ),
      ],
    );
  }

  Widget _buildMemberDropdown({
    String? value,
    required ValueChanged<String?> onChanged,
    String? excludeId,
  }) {
    final availableMembers =
        widget.members.where((m) => m.userId != excludeId).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('Select a member'),
          items: availableMembers.map((member) {
            return DropdownMenuItem<String>(
              value: member.userId,
              child: Row(
                children: [
                  AvatarCircle(
                    colorHex: member.colorAvatar,
                    initials: member.initials,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(member.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _toggleOption(String option) {
    setState(() {
      if (widget.question.allowMultiple) {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
      } else {
        _selectedOptions.clear();
        _selectedOptions.add(option);
      }
    });
  }

  Widget _buildSubmitButton() {
    final canSubmit = _canSubmit();

    return ElevatedButton(
      onPressed: canSubmit && !widget.isSubmitting ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: widget.isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Submit Vote',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  bool _canSubmit() {
    switch (widget.question.questionType) {
      case QuestionType.binaryVote:
      case QuestionType.singleChoice:
        return _selectedOptions.isNotEmpty;
      case QuestionType.freeText:
        return _textController.text.trim().isNotEmpty;
      case QuestionType.memberChoice:
        return _selectedMember != null;
      case QuestionType.duoChoice:
        return _selectedMember != null && _selectedMember2 != null;
    }
  }

  void _handleSubmit() {
    List<String> answers;

    switch (widget.question.questionType) {
      case QuestionType.binaryVote:
      case QuestionType.singleChoice:
        answers = _selectedOptions.toList();
        break;
      case QuestionType.freeText:
        answers = [_textController.text.trim()];
        break;
      case QuestionType.memberChoice:
        answers = [_selectedMember!];
        break;
      case QuestionType.duoChoice:
        answers = [_selectedMember!, _selectedMember2!];
        break;
    }

    widget.onSubmit(answers);
  }
}

class _BinaryOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _BinaryOptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberOptionCard extends StatelessWidget {
  final GroupMember member;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberOptionCard({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(0.1)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AvatarCircle(
                colorHex: member.colorAvatar,
                initials: member.initials,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.displayName,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
