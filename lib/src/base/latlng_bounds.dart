import 'dart:math' as math;

import 'package:leaflet_map/src/base/latlng.dart';

class LatLngBounds {
  LatLng northEast;
  LatLng southWest;

  LatLngBounds(LatLng latlng) {
    this._extend(latlng);
  }


  LatLngBounds.fromCorners(LatLng corner1, LatLng corner2){
    this._extend(corner1);
    this._extend(corner2);
  }

  _extend(LatLng latlng) {
    if (this.northEast == null && this.southWest == null) {
      this.southWest = new LatLng(latlng.lat, latlng.lng);
      this.northEast = new LatLng(latlng.lat, latlng.lng);

    } else {
      this.southWest.lat = math.min(latlng.lat, this.southWest.lat);
      this.southWest.lng = math.min(latlng.lng, this.southWest.lng);
      this.northEast.lat = math.max(latlng.lat, this.northEast.lat);
      this.northEast.lng = math.max(latlng.lng, this.northEast.lng);
    }
  }

  LatLngBounds pad(double bufferRatio) {
    LatLng sw = this.southWest,
        ne = this.northEast;
    double heightBuffer = (sw.lat - ne.lat).abs() * bufferRatio,
        widthBuffer = (sw.lng - ne.lng).abs() * bufferRatio;

    return new LatLngBounds.fromCorners(
        new LatLng(sw.lat - heightBuffer, sw.lng - widthBuffer),
        new LatLng(ne.lat + heightBuffer, ne.lng + widthBuffer)
    );
  }

  LatLng get center =>
      new LatLng(
          (this.southWest.lat + this.northEast.lat) / 2,
          (this.southWest.lng + this.northEast.lng) / 2
      );

  double get north => this.northEast.lat;

  double get east => this.northEast.lng;

  double get south => this.southWest.lat;

  double get west => this.southWest.lng;

  LatLng get northWest => new LatLng(this.north, this.west);

  LatLng get southEast => new LatLng(this.south, this.east);

  bool contains(LatLng corner) => this._contains(this.southWest, this.northEast);
  
  bool _contains(LatLng sw, LatLng ne) => sw.lat >= this.southWest.lat
      && ne.lat <= this.northEast.lat
      && sw.lng >= this.southWest.lng
      && ne.lng <= this.northEast.lng;

  bool _containsExt(LatLng sw, LatLng ne) => sw.lat > this.southWest.lat
      && ne.lat < this.northEast.lat
      && sw.lng > this.southWest.lng
      && ne.lng < this.northEast.lng;
  
  bool containBounds(LatLngBounds bounds) => this._contains(bounds.southWest, bounds.northEast);

  bool intersects(LatLngBounds bounds) => this.containBounds(bounds);

  bool overlaps(LatLngBounds bounds) => this._containsExt(bounds.southWest, bounds.northEast);

  String get bboxString => '$west,$south,$east,$north';

  bool equals(LatLngBounds bounds, {double maxMargin = 1.0E-9}){
    LatLng sw1 = this.southWest, ne1 = this.northEast,
      sw2 = bounds.southWest, ne2 = bounds.northEast;
    return math.max((sw1.lat - sw2.lat).abs(), (sw1.lng - sw2.lng).abs()) <= maxMargin
        && math.max((ne1.lat - ne2.lat).abs(), (ne1.lng - ne2.lng).abs()) <= maxMargin;
  }

  bool get isValid => this.southWest != null && this.northEast != null;

}