// lib/utils/safe_curve.dart
//
// Clamps animation values to [0, 1] to prevent floating-point
// precision errors that can cause assertion failures in Flutter's
// animation system (e.g., value slightly outside [0.0, 1.0]).

import 'package:flutter/material.dart';

/// Wraps an Animation<double> and clamps its value to [0.0, 1.0].
/// Use this to prevent CurveTween assertion errors.
class ClampedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  ClampedAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value.clamp(0.0, 1.0);
}
