import 'package:flutter/material.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => child,
    );
  }
}

/*
// lib/core/navigation/bottom_sheet_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom BottomSheetPage that works with GoRouter
class BottomSheetPage<T> extends Page<T> {
  final Widget child;
  final bool isScrollControlled;
  final bool useSafeArea;
  final bool enableDrag;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final AnimationController? transitionAnimationController;
  final String? barrierLabel;
  final Color? barrierColor;
  final bool dismissible;
  final RouteSettings? routeSettings;

  const BottomSheetPage({
    required this.child,
    this.isScrollControlled = true,
    this.useSafeArea = true,
    this.enableDrag = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.transitionAnimationController,
    this.barrierLabel,
    this.barrierColor,
    this.dismissible = true,
    this.routeSettings,
    super.key,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return _BottomSheetRoute<T>(
      child: child,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      transitionAnimationController: transitionAnimationController,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      dismissible: dismissible,
      settings: routeSettings ?? this,
    );
  }
}

class _BottomSheetRoute<T> extends PopupRoute<T> {
  final Widget child;
  final bool isScrollControlled;
  final bool useSafeArea;
  final bool enableDrag;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final AnimationController? transitionAnimationController;
  final String? barrierLabel;
  final Color? barrierColor;
  final bool dismissible;

  _BottomSheetRoute({
    required this.child,
    required this.isScrollControlled,
    required this.useSafeArea,
    required this.enableDrag,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.transitionAnimationController,
    this.barrierLabel,
    this.barrierColor,
    this.dismissible = true,
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => this.barrierColor ?? Colors.black54;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => this.barrierLabel ?? 'Bottom sheet';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  AnimationController createAnimationController() {
    return transitionAnimationController ??
        super.createAnimationController() as AnimationController;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _BottomSheetPage(
      child: child,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      animation: animation,
    );
  }
}

class _BottomSheetPage extends StatelessWidget {
  final Widget child;
  final bool isScrollControlled;
  final bool useSafeArea;
  final bool enableDrag;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Animation<double> animation;

  const _BottomSheetPage({
    required this.child,
    required this.isScrollControlled,
    required this.useSafeArea,
    required this.enableDrag,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 100),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: SafeArea(
        top: false,
        child: Material(
          color: backgroundColor ?? Theme.of(context).colorScheme.surface,
          elevation: elevation ?? 8.0,
          shape: shape ??
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
          clipBehavior: clipBehavior ?? Clip.antiAlias,
          child: isScrollControlled
              ? DraggableScrollableSheet(
                  initialChildSize: 0.8,
                  minChildSize: 0.4,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) {
                    return _BottomSheetContent(
                      child: child,
                      scrollController: scrollController,
                      useSafeArea: useSafeArea,
                    );
                  },
                )
              : _BottomSheetContent(
                  child: child,
                  useSafeArea: useSafeArea,
                ),
        ),
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;
  final bool useSafeArea;

  const _BottomSheetContent({
    required this.child,
    this.scrollController,
    required this.useSafeArea,
  });

  @override
  Widget build(BuildContext context) {
    final content = scrollController != null
        ? SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(context),
                child,
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(context),
              child,
            ],
          );

    return useSafeArea
        ? SafeArea(
            top: false,
            bottom: true,
            child: content,
          )
        : content;
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      width: double.infinity,
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
*/
