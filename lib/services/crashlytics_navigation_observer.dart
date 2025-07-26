// lib/services/crashlytics_navigation_observer.dart
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenChange(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenChange(previousRoute, 'pop_to');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenChange(newRoute, 'replace');
    }
  }

  void _logScreenChange(Route<dynamic> route, String action) {
    final screenName = _getScreenName(route);
    FirebaseCrashlytics.instance.log('Screen $action: $screenName');
    FirebaseCrashlytics.instance.setCustomKey('current_screen', screenName);
    FirebaseCrashlytics.instance.setCustomKey('last_navigation_action', action);
    FirebaseCrashlytics.instance.setCustomKey('last_navigation_time', DateTime.now().toIso8601String());
  }

  String _getScreenName(Route<dynamic> route) {
    if (route.settings.name != null) {
      return route.settings.name!;
    }
    
    // Try to extract class name from route
    final routeString = route.toString();
    if (routeString.contains('MaterialPageRoute')) {
      // Try to extract the widget class name
      final match = RegExp(r'MaterialPageRoute<[^>]*>\(.*?(\w+Screen|\w+Page)').firstMatch(routeString);
      if (match != null) {
        return match.group(1) ?? 'Unknown';
      }
    }
    
    return 'Unknown';
  }
}