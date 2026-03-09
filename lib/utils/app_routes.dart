enum MainTabRoute {
  home,
  members,
  history,
  settings,
}

extension MainTabRouteX on MainTabRoute {
  String get segment {
    switch (this) {
      case MainTabRoute.home:
        return 'home';
      case MainTabRoute.members:
        return 'members';
      case MainTabRoute.history:
        return 'history';
      case MainTabRoute.settings:
        return 'settings';
    }
  }

  static MainTabRoute? fromSegment(String segment) {
    switch (segment) {
      case 'home':
        return MainTabRoute.home;
      case 'members':
        return MainTabRoute.members;
      case 'history':
        return MainTabRoute.history;
      case 'settings':
        return MainTabRoute.settings;
      default:
        return null;
    }
  }
}

class GroupTabDeepLink {
  final String groupId;
  final MainTabRoute tab;

  const GroupTabDeepLink({
    required this.groupId,
    required this.tab,
  });
}

class AppRoutePaths {
  static const groupsMessageQueryKey = 'message';

  static const root = '/';
  static const auth = '/auth';
  static const welcome = '/welcome';
  static const groups = '/groups';
  static const join = '/join';
  static const create = '/create';
  static const main = '/main';

  static MainTabRoute tabFromIndex(int index) {
    switch (index) {
      case 0:
        return MainTabRoute.home;
      case 1:
        return MainTabRoute.members;
      case 2:
        return MainTabRoute.history;
      case 3:
        return MainTabRoute.settings;
      default:
        return MainTabRoute.home;
    }
  }

  static String groupTab(String groupId, MainTabRoute tab) {
    final encodedGroupId = Uri.encodeComponent(groupId);
    return '/groups/$encodedGroupId/${tab.segment}';
  }

  static String groupHome(String groupId) {
    return groupTab(groupId, MainTabRoute.home);
  }

  static String groupsWithMessage(String message) {
    return Uri(
      path: groups,
      queryParameters: {
        groupsMessageQueryKey: message,
      },
    ).toString();
  }

  static String? parseGroupsMessage(String? routeName) {
    if (routeName == null || routeName.isEmpty) return null;

    final uri = Uri.tryParse(routeName);
    if (uri == null || uri.path != groups) return null;

    final value = uri.queryParameters[groupsMessageQueryKey];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  static GroupTabDeepLink? parseGroupTabPath(String? routeName) {
    if (routeName == null || routeName.isEmpty) return null;

    final uri = Uri.tryParse(routeName);
    if (uri == null) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2 || segments.first != 'groups') {
      return null;
    }

    final decodedGroupId = Uri.decodeComponent(segments[1]);
    if (decodedGroupId.isEmpty) return null;

    if (segments.length == 2) {
      return GroupTabDeepLink(
        groupId: decodedGroupId,
        tab: MainTabRoute.home,
      );
    }

    if (segments.length == 3) {
      final tab = MainTabRouteX.fromSegment(segments[2]);
      if (tab == null) return null;
      return GroupTabDeepLink(groupId: decodedGroupId, tab: tab);
    }

    return null;
  }
}
