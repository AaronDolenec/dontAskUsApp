import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(leaderboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: members.isEmpty
          ? const Center(child: Text('No leaderboard data available.'))
          : ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(member.displayName),
                  subtitle: Text('Streak: ${member.answerStreak}'),
                );
              },
            ),
    );
  }
}
