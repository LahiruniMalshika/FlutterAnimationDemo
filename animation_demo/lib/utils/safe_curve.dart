import 'package:flutter/material.dart';

class ClampedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  ClampedAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value.clamp(0.0, 1.0);
}

class SafeCurve extends Curve {
  final Curve curve;
  const SafeCurve(this.curve);

  @override
  double transformInternal(double t) {
    return curve.transformInternal(t.clamp(0.0, 1.0));
  }
}

extension CurveSafety on Curve {
  Curve get safe => SafeCurve(this);
}

CurvedAnimation createSafeCurvedAnimation({
  required Animation<double> parent,
  required Curve curve,
}) {
  return CurvedAnimation(
    parent: ClampedAnimation(parent),
    curve: curve,
  );
}
