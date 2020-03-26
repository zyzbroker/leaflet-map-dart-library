import 'dart:math' as math;

import 'latlng.dart';
import 'package:leaflet/src/utility/helper.dart' as h;

class Point<T extends num> {
  T _x;
  T _y;
  T _z;

  T get x => this._x;
  T get y => this._y;
  T get z => this._z;
  set z(T value) => this._z = value;

  Point(this._x, this._y);

  factory Point.fromList(List<T> xy){
    if(xy == null || xy.length != 2){
      throw new Exception('The list must have two items.');
    }
    return new Point(xy[0],xy[1]);
  }

  factory Point.fromLatLng(LatLng latlng){
    num lX = latlng.lat, lY = latlng.lng;
    return new Point(lX, lY);
  }

  factory Point.fromString(String value,[String separator=',']){
    List<String> xy = value.split(separator);
    if (xy.length < 2) {
      throw new ArgumentError('The point string format is invalid:($value). The valid format is x,y');
    }
    return new Point(num.parse(xy[0]), num.parse(xy[1]));
  }

  String toString() => '${this._x},${this._y},${this._z}';

  Point<T> clone() => new Point<T>(this.x, this.y);

  bool operator == (dynamic point) {
    if (point is Point<T>){
      return this._x == point.x && this._y == point.y;
    }
    return false;
  }

  Point<T> operator / (num divider) {
    if (divider.round() == 0){
      throw new Exception('The divider can not be 0');
    }
    num numX = this._x / divider;
    num numY = this._y / divider;
    return new Point(numX, numY);
  }

  double distanceTo(Point<T> other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Point<T> scaleBy(Point<T> point) => new Point<T>(this._x * point.x, this._y * point.y);
  Point<T> unScaleBy(Point<T> point){
    num nX = this._x / point.x, nY = this._y / point.y;
    return new Point(nX, nY);
  }

  Point<T> operator - (Point<T> point) => new Point<T>(this._x - point.x, this._y - point.y);


  bool operator >= (Point<T> point) => this.x >= point.x && this.y >= point.y;

  bool operator <= (Point<T> point) => this.x <= point.x && this.y <= point.y;

  Point<T> operator * (num factor) =>
      new Point(this.x * factor, this.y * factor);

  Point<T> operator + (Point<T> point) => new Point<T>(this.x + point.x, this.y + point.y);

  Point<num> round() {
    num x = this.x,
        y = this.y;
    return new Point(x.round(), y.round());
  }

  Point<T> floor(){
    if (this._x is double && this._y is double){
      num x = this._x.floor(), y = this._y.floor();
      return new Point(x, y);
    }
    return this;
  }

  Point<T> ceil(){
    if (this._x is double && this._y is double){
      num x = this._x.ceil(), y = this._y.ceil();
      return new Point(x, y);
    }
    return this;
  }


  bool contains(Point<T> point) {
    num x = this.x, y = this.y;
    return point.x.abs() <= x.abs() && point.y.abs() <= y.abs();
  }
  
  Point<num> trunc(){
    return new Point<num>(
      h.trunc(this.x),
      h.trunc(this.y)
    );
  }
}
