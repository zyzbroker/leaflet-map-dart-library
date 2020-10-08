import 'dart:math' as math;
import 'package:tuple/tuple.dart';

import 'latlng.dart';
import 'point.dart';
import 'bounds.dart';
import 'transformation.dart';
import 'projection.dart';
import 'package:leaflet_map/src/utility/helper.dart' as h;
import 'latlng_bounds.dart';


abstract class CRS {
  Projection projection;
  bool infinite = false;
  Transformation transformation;
  Tuple2<double, double> wrapLng;
  Tuple2<double,double> wrapLat;

  Point<num> latLngToPoint(LatLng latlng, double zoom){
    Point p = this.projection.project(latlng);
    double scale = this.scale(zoom);

    return this.transformation.transform(p, scale: scale);
  }

  LatLng pointToLatLng(Point point, double zoom){
    double scale = this.scale(zoom);
    Point p = this.transformation.reverse(point, scale: scale);
    return this.projection.unproject(p);
  }

  Point project(LatLng latlng) => this.projection.project(latlng);

  LatLng unproject(Point point) => this.projection.unproject(point);

  Bounds getProjectedBounds(double zoom) {
    if(this.infinite) {return null;}

    Bounds b = this.projection.bounds;
    double s = this.scale(zoom);
    Point min = this.transformation.transform(b.min, scale: s);
    Point max = this.transformation.transform(b.max, scale: s);

    return new Bounds.fromPoints([min,max]);
  }

  double scale(double zoom){
    return 256 * math.pow(2, zoom);
  }

  double zoom(double scale){
    return math.log(scale / 256) / math.ln2;
  }

  LatLng wrapLatLng(LatLng latlng){
    double lng = this.wrapLng != null ?
      h.wrapNum(latlng.lng, this.wrapLng, true) : latlng.lng;
    double lat = this.wrapLat != null ?
      h.wrapNum(latlng.lat, this.wrapLat, true) : latlng.lat;
    return new LatLng(lat,lng);
  }

  LatLngBounds wrapLatLngBounds(LatLngBounds bounds){
    LatLng center = bounds.center;
    LatLng newCenter = this.wrapLatLng(center);
    double latShift = center.lat - newCenter.lat;
    double lngShift = center.lng - newCenter.lng;
    if(latShift == 0 && lngShift == 0) {
      return bounds;
    }
    LatLng sw = bounds.southWest, ne = bounds.northEast,
      newSw = new LatLng(sw.lat - latShift, sw.lng - lngShift),
      newNe = new LatLng(ne.lat - latShift, ne.lng - lngShift);

    return new LatLngBounds.fromCorners(newSw, newNe);
  }
}