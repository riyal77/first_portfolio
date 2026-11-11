import 'package:flutter/widgets.dart';

/// Scroll horizontal yang berhenti tepat di awal tiap item selebar
/// [itemExtent] (setara CSS `scroll-snap-align: start`).
class SnapToItemPhysics extends ScrollPhysics {
  const SnapToItemPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  SnapToItemPhysics applyTo(ScrollPhysics? ancestor) =>
      SnapToItemPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _target(ScrollMetrics position, Tolerance tolerance, double velocity) {
    var index = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      index -= 0.5;
    } else if (velocity > tolerance.velocity) {
      index += 0.5;
    }
    return (index.roundToDouble() * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _target(position, tolerance, velocity);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
