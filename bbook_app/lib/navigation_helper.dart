import 'package:flutter/material.dart';
import 'loadingPage.dart';

class NavigationHelper {
  static final List<String> _navigationStack = [];

  static Future<void> navigate(
    BuildContext context,
    String routeName, {
    bool replacement = false,
    Duration loadingDuration = const Duration(seconds: 2),
    bool canGoBack = true,
  }) async {
    try {
      if (replacement) {
        _navigationStack.clear();
        _navigationStack.add(routeName);

        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingPage(
              nextRoute: routeName,
              loadingDuration: loadingDuration,
              canGoBack: canGoBack,
            ),
          ),
          (route) => false,
        );
      } else {
        _navigationStack.add(routeName);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingPage(
              nextRoute: routeName,
              loadingDuration: loadingDuration,
              canGoBack: canGoBack,
            ),
          ),
        );
      }
    } catch (e) {
      print('Navigation error: $e');
    }
  }

  static Future<void> goBack(
    BuildContext context, {
    Duration loadingDuration = const Duration(seconds: 2),
  }) async {
    if (_navigationStack.length < 2) {
      return;
    }

    _navigationStack.removeLast();
    String previousRoute = _navigationStack.last;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingPage(
          nextRoute: previousRoute,
          loadingDuration: loadingDuration,
          canGoBack: _navigationStack.length > 1,
        ),
      ),
    );
  }

  static String? getCurrentRoute() {
    return _navigationStack.isNotEmpty ? _navigationStack.last : null;
  }

  static String? getPreviousRoute() {
    return _navigationStack.length > 1 
        ? _navigationStack[_navigationStack.length - 2] 
        : null;
  }
}