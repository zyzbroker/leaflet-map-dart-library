import 'dart:math' as math;

import 'earth.dart';
import 'SphericalMercator.dart';
import 'projection.dart';
import 'transformation.dart';

class EPSG3857 extends Earth {
  final String code = 'EPSG:3857';
  final Projection projection;
  final Transformation transformation;

  EPSG3857():
      projection = new SphericalMercator(),
      transformation = _transformation,
      super();

  static Transformation get _transformation {
    double scale = 0.5 / (math.pi * SphericalMercator.R);
    return new Transformation(scale, 0.5, -scale, 0.5);
  }

}
