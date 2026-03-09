import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../utils/app_colors.dart';

class GroupContextAppBarTitle extends ConsumerWidget {
  final String title;

  const GroupContextAppBarTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final groupInfo = ref.watch(groupInfoProvider).valueOrNull;

    String groupName = groupInfo?.name ?? '';
    if (groupName.isEmpty &&
        authState.user != null &&
        authState.groupId != null) {
      for (final membership in authState.user!.groups) {
        if (membership.groupId == authState.groupId &&
            membership.groupName.isNotEmpty) {
          groupName = membership.groupName;
          break;
        }
      }
    }
    if (groupName.isEmpty) {
      groupName = 'Current Group';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Text(
          groupName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
