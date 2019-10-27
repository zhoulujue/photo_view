import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:photo_view/src/photo_view_image_wrapper.dart';

import '../photo_view_scale_state.dart';
import '../photo_view_typedefs.dart';
import '../photo_view_utils.dart';
import 'photo_view_controller.dart';

/// A  class to hold internal layout logic to sync both controller states
mixin PhotoViewControllerDelegate on State<PhotoViewImageWrapper> {
  PhotoViewControllerBase get controller => widget.controller;

  PhotoViewScaleStateController get scaleStateController =>
      widget.scaleStateController;

  ScaleBoundaries get scaleBoundaries => widget.scaleBoundaries;

  ScaleStateCycle get scaleStateCycle => widget.scaleStateCycle;

  Alignment get basePosition => widget.basePosition;
  OffsetWrapper _lastOffsetWrapper;
  Function(double prevScale, double nextScale) _animateScale;

  void startListeners() {
    controller.addIgnorableListener(_blindScaleListener);
    scaleStateController.addIgnorableListener(_blindScaleStateListener);
  }

  void _blindScaleStateListener() {
    if (!scaleStateController.hasChanged) {
      return;
    }
    if (_animateScale == null || scaleStateController.isZooming) {
      controller.setScaleInvisibly(scale);
      return;
    }
    final double prevScale = controller.scale ??
        getScaleForScaleState(
          scaleStateController.prevScaleState,
          scaleBoundaries,
        );

    final double nextScale = getScaleForScaleState(
      scaleStateController.scaleState,
      scaleBoundaries,
    );

    _animateScale(prevScale, nextScale);
  }

  void addAnimateOnScaleStateUpdate(
      void animateScale(double prevScale, double nextScale)) {
    _animateScale = animateScale;
  }

  void _blindScaleListener() {
    if (controller.scale == controller.prevValue.scale) {
      return;
    }
    final PhotoViewScaleState newScaleState =
        (scale > scaleBoundaries.initialScale)
            ? PhotoViewScaleState.zoomedIn
            : PhotoViewScaleState.zoomedOut;

    scaleStateController.setInvisibly(newScaleState);
    controller.position = clampPosition(controller.position);
  }

  double get scale {
    return controller.scale ??
        getScaleForScaleState(
          scaleStateController.scaleState,
          scaleBoundaries,
        );
  }

  set scale(double scale) {
    controller.setScaleInvisibly(scale);
  }

  void updateMultiple({
    Offset position,
    double scale,
    double rotation,
    Offset rotationFocusPoint,
  }) {
    controller.updateMultiple(
        position: position,
        scale: scale,
        rotation: rotation,
        rotationFocusPoint: rotationFocusPoint);
  }

  void updateScaleStateFromNewScale(double scaleFactor, double newScale) {
    if (scaleFactor == 1.0) {
      return;
    }

    final PhotoViewScaleState newScaleState =
        (newScale > scaleBoundaries.initialScale)
            ? PhotoViewScaleState.zoomedIn
            : PhotoViewScaleState.zoomedOut;

    scaleStateController.setInvisibly(newScaleState);
  }

  void checkAndSetToInitialScaleState() {
    if (scaleStateController.scaleState != PhotoViewScaleState.initial &&
        scale == scaleBoundaries.initialScale) {
      scaleStateController.setInvisibly(PhotoViewScaleState.initial);
    }
  }

  void nextScaleState() {
    final PhotoViewScaleState scaleState = scaleStateController.scaleState;
    if (scaleState == PhotoViewScaleState.zoomedIn ||
        scaleState == PhotoViewScaleState.zoomedOut) {
      scaleStateController.scaleState = scaleStateCycle(scaleState);
      return;
    }
    final double originalScale = getScaleForScaleState(
      scaleState,
      scaleBoundaries,
    );

    double prevScale = originalScale;
    PhotoViewScaleState prevScaleState = scaleState;
    double nextScale = originalScale;
    PhotoViewScaleState nextScaleState = scaleState;

    do {
      prevScale = nextScale;
      prevScaleState = nextScaleState;
      nextScaleState = scaleStateCycle(prevScaleState);
      nextScale = getScaleForScaleState(nextScaleState, scaleBoundaries);
    } while (prevScale == nextScale && scaleState != nextScaleState);

    if (originalScale == nextScale) {
      return;
    }
    scaleStateController.scaleState = nextScaleState;
  }

  Offset clampPosition(Offset offset, {double scale}) {
    final double _scale = scale ?? this.scale;
    final double x = offset.dx;
    final double y = offset.dy;

    final double computedWidth = scaleBoundaries.childSize.width * _scale;
    final double computedHeight = scaleBoundaries.childSize.height * _scale;

    final double screenWidth = scaleBoundaries.outerSize.width;
    final double screenHeight = scaleBoundaries.outerSize.height;

    final double positionX = basePosition.x;
    final double positionY = basePosition.y;

    final double widthDiff = computedWidth - screenWidth;
    final double heightDiff = computedHeight - screenHeight;

    final double minX = ((positionX - 1).abs() / 2) * widthDiff * -1;
    final double maxX = ((positionX + 1).abs() / 2) * widthDiff;

    final double minY = ((positionY - 1).abs() / 2) * heightDiff * -1;
    final double maxY = ((positionY + 1).abs() / 2) * heightDiff;

    final double computedX =
        screenWidth < computedWidth ? x.clamp(minX, maxX) : 0.0;

    final double computedY =
        screenHeight < computedHeight ? y.clamp(minY, maxY) : 0.0;

    final result = OffsetWrapper(computedX, computedY, x < minX, x > maxX);
    _lastOffsetWrapper = result;
    return result;
  }

  bool moveTest(double scale, Offset delta) {
    if (scale != 1.0) {
      //when child is zooming
      return true;
    }
    if (_lastOffsetWrapper != null) {
      final moveRight = delta.dx < 0;
      if (_lastOffsetWrapper.reachLeftBound) {
        return moveRight;
      } else if (_lastOffsetWrapper.reachRightBound) {
        return !moveRight;
      }
    }

    return scaleStateController.scaleState != PhotoViewScaleState.initial;
  }

  @override
  void dispose() {
    _animateScale = null;
    controller.removeIgnorableListener(_blindScaleListener);
    scaleStateController.removeIgnorableListener(_blindScaleStateListener);
    super.dispose();
  }
}

class OffsetWrapper extends Offset {
  OffsetWrapper(double dx, double dy, this.reachRightBound, this.reachLeftBound)
      : super(dx, dy);
  final bool reachLeftBound;
  final bool reachRightBound;
}