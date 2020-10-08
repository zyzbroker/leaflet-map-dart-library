import 'dart:math' as math;
import 'package:leaflet/src/utility/helper.dart' as h;
import 'package:leaflet/src/base/earth.dart';
//import 'package:leaflet/src/base/latlng_bounds.dart';

class LatLng {
  num lat;
  num lng;
  num alt;

  LatLng(this.lat, this.lng, [num this.alt]) {
      if (this.lat == null || this.lng == null) {
          throw new ArgumentError('Latitude and Longitude are required.');
      }
  }

  bool equals(LatLng obj, [num maxMargin = 1.0E-9]) {
    var margin = math.max((this.lat - obj.lat).abs(), (this.lng - obj.lng).abs());
    return margin <= maxMargin;
  }

  @override
  String toString([num precision]) =>
    'LatLng(${h.formatNum(this.lat, precision)}, ${h.formatNum(this.lng, precision)})';

  num distanceTo(LatLng other) => new Earth().distance(this, other);

  LatLng wrap() => new Earth().wrapLatLng(this);

  LatLng clone() => new LatLng(this.lat, this.lng, this.alt);

  toBounds(num sizeInMeters){
    var latAccu = 180 * sizeInMeters / 40075017,
      lngAccu = latAccu / math.cos((math.pi / 180) * this.lat);

    return h.toLatLngBounds(
        [this.lat - latAccu, this.lng - lngAccu],
        [this.lat + latAccu, this.lng + lngAccu]);
  }

}
