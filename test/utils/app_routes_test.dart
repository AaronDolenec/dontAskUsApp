import 'package:flutter_test/flutter_test.dart';
import 'package:dont_ask_us/utils/app_routes.dart';

void main() {
  group('AppRoutePaths.parseGroupTabPath', () {
    test('parses /groups/:id/:tab', () {
      final deepLink =
          AppRoutePaths.parseGroupTabPath('/groups/abc123/settings');

      expect(deepLink, isNotNull);
      expect(deepLink!.groupId, 'abc123');
      expect(deepLink.tab, MainTabRoute.settings);
    });

    test('defaults to home for /groups/:id', () {
      final deepLink = AppRoutePaths.parseGroupTabPath('/groups/abc123');

      expect(deepLink, isNotNull);
      expect(deepLink!.groupId, 'abc123');
      expect(deepLink.tab, MainTabRoute.home);
    });

    test('handles encoded group id', () {
      final deepLink = AppRoutePaths.parseGroupTabPath(
        '/groups/team%20space/members',
      );

      expect(deepLink, isNotNull);
      expect(deepLink!.groupId, 'team space');
      expect(deepLink.tab, MainTabRoute.members);
    });

    test('returns null for invalid paths', () {
      expect(AppRoutePaths.parseGroupTabPath('/groups'), isNull);
      expect(AppRoutePaths.parseGroupTabPath('/groups/abc123/unknown'), isNull);
      expect(AppRoutePaths.parseGroupTabPath('/auth'), isNull);
    });
  });

  group('AppRoutePaths.groupTab', () {
    test('builds canonical group tab path', () {
      expect(
        AppRoutePaths.groupTab('g-1', MainTabRoute.history),
        '/groups/g-1/history',
      );
    });

    test('encodes group ids when building path', () {
      expect(
        AppRoutePaths.groupTab('team space', MainTabRoute.home),
        '/groups/team%20space/home',
      );
    });
  });

  group('AppRoutePaths groups message helpers', () {
    test('builds groups route with encoded message query', () {
      final path = AppRoutePaths.groupsWithMessage('Could not open group');

      expect(path, '/groups?message=Could+not+open+group');
    });

    test('parses groups message query', () {
      final message = AppRoutePaths.parseGroupsMessage(
        '/groups?message=Could%20not%20open%20group',
      );

      expect(message, 'Could not open group');
    });

    test('returns null when message query is missing or unrelated', () {
      expect(AppRoutePaths.parseGroupsMessage('/groups'), isNull);
      expect(AppRoutePaths.parseGroupsMessage('/groups?message='), isNull);
      expect(AppRoutePaths.parseGroupsMessage('/auth?message=test'), isNull);
    });
  });
}
