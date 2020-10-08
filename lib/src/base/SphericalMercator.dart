import 'dart:math' as math;

import 'package:leaflet_map/src/base/latlng.dart';

import 'point.dart' as p;
import 'bounds.dart';
import 'projection.dart';

class SphericalMercator implements Projection {
  static const int R = 6378137;
  static const num MAX_LATITUDE = 85.0511287798;

  p.Point<num> project(LatLng latlng){
    var d = math.pi / 180,
        max = MAX_LATITUDE,
        lat = math.max(math.min(max, latlng.lat), -max),
        sin = math.sin(lat * d);

    return new p.Point(
      SphericalMercator.R * latlng.lng * d,
      SphericalMercator.R * math.log((1 + sin) / (1 - sin)) / 2,
    );
  }

  LatLng unproject(p.Point point){
    double d = 180 / math.pi;
    return new LatLng(
        (2 * math.atan(math.exp(point.y / SphericalMercator.R)) - (math.pi / 2)) * d,
        point.x * d / SphericalMercator.R);
  }

  Bounds get bounds {
    double d = SphericalMercator.R * math.pi;
    return new Bounds.fromPoints([
      new p.Point(-d,-d),
      new p.Point(d,d)
    ]);
  }
}