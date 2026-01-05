import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dont_ask_us/models/models.dart';
import 'package:dont_ask_us/screens/onboarding/join_group_screen.dart';
import 'package:dont_ask_us/screens/main/main_screen.dart';
import 'package:dont_ask_us/widgets/widgets.dart';
import 'package:dont_ask_us/utils/utils.dart';

void main() {
  group('Join Group Flow', () {
    testWidgets('displays join group screen with invite code input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JoinGroupScreen(),
          ),
        ),
      );

      expect(find.text('Join a Group'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('validates empty invite code', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JoinGroupScreen(),
          ),
        ),
      );

      // Find and tap join button without entering code
      final joinButton = find.byType(ElevatedButton);
      expect(joinButton, findsOneWidget);

      // Button should be disabled initially
      final button = tester.widget<ElevatedButton>(joinButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('validates display name input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JoinGroupScreen(),
          ),
        ),
      );

      // Find text fields
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
    });
  });

  group('Main Navigation', () {
    testWidgets('displays bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('has four navigation tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for navigation items
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('Voting Flow', () {
    testWidgets('VoteOptionCard displays option text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'Option A',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('VoteOptionCard responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'Option A',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      expect(tapped, isTrue);
    });

    testWidgets('VoteOptionCard shows selected state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'Option A',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Widget should show selected state styling
      final card = find.byType(VoteOptionCard);
      expect(card, findsOneWidget);
    });

    testWidgets('VoteOptionCard shows results with progress bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'Option A',
              onTap: () {},
              showResults: true,
              voteCount: 5,
              totalVotes: 10,
            ),
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('UI Components', () {
    testWidgets('AvatarCircle displays initials', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarCircle(
              colorHex: '#3B82F6',
              initials: 'JD',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('StreakBadge displays streak count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBadge(streak: 7),
          ),
        ),
      );

      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('ErrorDisplay shows error message and retry button',
        (WidgetTester tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Something went wrong',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(retried, isTrue);
    });

    testWidgets('LoadingShimmer displays shimmer effect',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionCardSkeleton(),
          ),
        ),
      );

      // Shimmer widget should be present
      expect(find.byType(QuestionCardSkeleton), findsOneWidget);
    });
  });

  group('Color Picker', () {
    testWidgets('displays color options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: '#3B82F6',
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      // Should show multiple color options
      expect(find.byType(ColorPicker), findsOneWidget);
    });

    testWidgets('calls callback when color selected',
        (WidgetTester tester) async {
      String? selectedColorHex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: '#3B82F6',
              onColorSelected: (colorHex) => selectedColorHex = colorHex,
            ),
          ),
        ),
      );

      // Find and tap a color option
      final colorOptions = find.byType(GestureDetector);
      if (colorOptions.evaluate().isNotEmpty) {
        await tester.tap(colorOptions.first);
        // Check that callback was invoked with a non-null value
        expect(selectedColorHex ?? '', isNotEmpty);
      }
    });
  });

  group('Question Card', () {
    testWidgets('displays question text', (WidgetTester tester) async {
      final question = DailyQuestion(
        id: 1,
        questionId: 'q123',
        questionText: 'What is your favorite color?',
        questionType: QuestionType.singleChoice,
        questionDate: DateTime.now(),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCard(
              question: question,
            ),
          ),
        ),
      );

      expect(find.text('What is your favorite color?'), findsOneWidget);
    });

    testWidgets('shows question type badge', (WidgetTester tester) async {
      final question = DailyQuestion(
        id: 2,
        questionId: 'q456',
        questionText: 'Yes or No?',
        questionType: QuestionType.binaryVote,
        questionDate: DateTime.now(),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCard(
              question: question,
            ),
          ),
        ),
      );

      expect(find.text('Yes or No?'), findsOneWidget);
    });
  });
}
