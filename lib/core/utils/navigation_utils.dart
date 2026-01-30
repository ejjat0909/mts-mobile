import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:sqlite_viewer2/sqlite_viewer.dart';

/// Pop with results class
class PopWithResults<T> {
  /// Popped from this page
  final String fromPage;

  /// Pop until this page
  final String toPage;

  /// Results
  final Map<String, T>? results;

  /// Constructor
  PopWithResults({required this.fromPage, required this.toPage, this.results});
}

/// Navigation utility functions
class NavigationUtils {
  /// Push named route
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push named route and remove until
  static Future<T?> pushNamedAndRemoveUntil<T>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil<T>(routeName, predicate, arguments: arguments);
  }

  /// Push named route and remove all
  static Future<T?> pushNamedAndRemoveAll<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Push replacement named route
  static Future<T?> pushReplacementNamed<T, TO>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Pop route
  static void pop<T>(BuildContext context, [T? result]) {
    if (canPop(context)) {
      Navigator.of(context).pop<T>(result);
    }
  }

  /// Pop until route
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  /// Pop until named route
  static void popUntilNamed(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }

  /// Can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  /// Push and remove until
  static void pushRemoveUntil(
    BuildContext context, {
    required Widget screen,
    bool? slideFromLeft,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(
            slideFromLeft != null ? -1.0 : 1.0,
            0.0,
          ); // Slide from right or left
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
      (Route<dynamic> route) => false,
    );
  }

  /// Create a route with slide transition
  static Route createRoute({
    required Widget newScreen,
    bool slideFromLeft = false,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(slideFromLeft ? -1.0 : 1.0, 0.0);
        const end = Offset(0.0, 0.0);
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  static Future<T?> navigateToLocalDB<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const DatabaseList()),
    );
  }

  /// Create an optimized route with slide transition for heavy screens
  /// This version uses a more efficient transition and allows for pre-initialization
  static Route createOptimizedRoute({
    required Widget newScreen,
    bool slideFromLeft = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Function? onTransitionStart,
    Function? onTransitionComplete,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Call onTransitionStart when animation begins
        if (onTransitionStart != null &&
            animation.status == AnimationStatus.forward) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onTransitionStart();
          });
        }

        // Call onTransitionComplete when animation completes
        if (onTransitionComplete != null) {
          animation.addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              onTransitionComplete();
            }
          });
        }

        final begin = Offset(slideFromLeft ? -1.0 : 1.0, 0.0);
        const end = Offset(0.0, 0.0);

        // Use a smoother curve for better performance
        const curve = Curves.fastOutSlowIn;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        // Use FadeTransition combined with SlideTransition for smoother animation
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// Create a non-blocking route that allows immediate interaction
  /// Perfect for screens with heavy initialization
  static Route createNonBlockingRoute({
    required Widget newScreen,
    bool slideFromLeft = false,
    Duration transitionDuration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        // Wrap the screen in a widget that allows immediate interaction
        return _NonBlockingWrapper(child: newScreen);
      },
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = Offset(slideFromLeft ? -1.0 : 1.0, 0.0);
        const end = Offset(0.0, 0.0);

        // Use easeOutCubic for the smoothest transition
        const curve = Curves.easeOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Show exit confirmation dialog
  static Future<bool> showExitPopup(
    BuildContext context, {
    Function()? onConfirm,
  }) async {
    // If cant pop then show this dialog
    if (!Navigator.canPop(context)) {
      // Unfocus from input field
      FocusScope.of(context).unfocus();
      // Show dialog
      return await ConfirmDialog.show(
            context,
            description: 'exitApp'.tr(),
            onPressed: () {
              if (onConfirm == null) {
                Navigator.of(context).pop(true);
                return;
              }
              onConfirm();
            },
            icon: const Icon(Icons.exit_to_app, size: 30, color: Colors.red),
          ) ??
          // If show dialog return null, return false
          false;
    } else {
      return true;
    }
  }
}

/// Wrapper widget that ensures immediate interaction capability
class _NonBlockingWrapper extends StatefulWidget {
  final Widget child;

  const _NonBlockingWrapper({required this.child});

  @override
  State<_NonBlockingWrapper> createState() => _NonBlockingWrapperState();
}

class _NonBlockingWrapperState extends State<_NonBlockingWrapper> {
  @override
  void initState() {
    super.initState();
    // Ensure the widget tree is built immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Force a rebuild to ensure all widgets are interactive
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
