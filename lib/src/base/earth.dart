import 'crs.dart';
import 'dart:math' as math;
import 'package:tuple/tuple.dart';
import 'package:leaflet_map/src/base/latlng.dart';

class Earth extends CRS {

  Earth(){
    this.wrapLng = const Tuple2<double, double>(-180.0, 180.0);
  }


  /// Mean Earth Radius.This value is recommended by
  /// the International Union of Geodesy and Geophysics.
  /// It minimizes the RMS relative error between the great circle and geodesic distance
  /// see http://rosettacode.org/wiki/Haversine_formula
  static final int R = 6371000;


  /// use Haversine formula to calculate distance
  /// see: https://www.movable-type.co.uk/scripts/latlong.html
  double distance(LatLng p1, LatLng p2) {
    var rad = math.pi / 180;
    var lat1 = p1.lat * rad,
      lat2 = p2.lat * rad,
      latDiff = (lat2 - lat1),
      lonDiff = (p2.lng - p1.lng),
      sinLatDiff = math.sin(latDiff * rad / 2),
      sinLonDiff = math.sin(lonDiff * rad / 2),
      a = math.pow(sinLatDiff, 2) + math.pow(sinLonDiff, 2) * math.cos(lat1) * math.cos(lat2),
      c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}