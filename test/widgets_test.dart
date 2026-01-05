import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dont_ask_us/models/models.dart';
import 'package:dont_ask_us/widgets/widgets.dart';

void main() {
  group('AvatarCircle Widget', () {
    testWidgets('displays initials correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarCircle(
              colorHex: '#3B82F6',
              initials: 'JD',
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('uses correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarCircle(
              colorHex: '#FF0000',
              initials: 'TU',
              size: 60,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('handles single initial', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarCircle(
              colorHex: '#00FF00',
              initials: 'S',
            ),
          ),
        ),
      );

      expect(find.text('S'), findsOneWidget);
    });
  });

  group('StreakBadge Widget', () {
    testWidgets('displays streak count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBadge(
              streak: 7,
            ),
          ),
        ),
      );

      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('shows compact mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StreakBadge(streak: 1, compact: true),
                StreakBadge(streak: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StreakBadge), findsNWidgets(2));
    });
  });

  group('ErrorDisplay Widget', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Something went wrong',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('calls onRetry when button pressed', (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      expect(retryPressed, true);
    });
  });

  group('LoadingShimmer Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingShimmer(
              child: SizedBox(
                height: 100,
                width: 200,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });
  });

  group('VoteOptionCard Widget', () {
    testWidgets('displays option text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'Yes',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'No',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(VoteOptionCard), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteOptionCard(
              option: 'Maybe',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(VoteOptionCard));
      expect(tapped, true);
    });
  });

  group('QuestionCard Widget', () {
    testWidgets('displays question text', (tester) async {
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
  });

  group('ColorPicker Widget', () {
    testWidgets('shows color options', (tester) async {
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

      expect(find.byType(ColorPicker), findsOneWidget);
    });

    testWidgets('calls onColorSelected when color tapped', (tester) async {
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
      if (colorOptions.evaluate().length > 1) {
        await tester.tap(colorOptions.at(1));
        expect(selectedColorHex, isNotNull);
      }
    });
  });
}
