import 'dart:io';

import 'package:flutter/cupertino.dart';

class FadePageRoute extends PageRouteBuilder {
  final Widget page;

  static void navigateToNextPage(BuildContext context, Widget routedPage) {
    if (Platform.isIOS) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => routedPage),
      );
    } else {
      Navigator.of(context).push(
        FadePageRoute(page: routedPage),
      );
    }
  }

  static void navigateToNextPageReplace(BuildContext context, Widget routedPage) {
    if (Platform.isIOS) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => routedPage),
      );
    } else {
      Navigator.of(context).pushReplacement (
        FadePageRoute(page: routedPage),
      );
    }
  }

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}