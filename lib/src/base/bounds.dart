import 'dart:math' as math;

import 'point.dart';

class Bounds {
  Point _min;
  Point _max;

  String toString() => 'min: ${this._min.toString()} max: ${this._max.toString()}';

  Point get min => this._min;
  Point get max => this._max;

  Bounds(Point point){
    _extend(point);
  }

  Bounds.fromPoints(List<Point> points){
    for(Point p in points){
      _extend(p);
    }
  }

  _extend(Point point){
    if(this._min == null && this._max == null){
      this._min = point.clone();
      this._max = point.clone();
    } else {
      this._min = new Point(
          math.min(this._min.x, point.x),
          math.min(this._min.y, point.y)
      );
      this._max = new Point(
          math.max(this._max.x, point.x),
          math.max(this._max.y, point.y)
      );
    }
  }

  Point get center => this._min * 0.5 + this._max * 0.5;

  Point get bottomLeft => new Point(this._min.x, this._max.y);

  Point get topRight => new Point(this._max.x, this._min.y);

  Point get topLeft => this._min;

  Point get bottomRight => this._max;

  Point get size => this._max - this._min;

  bool contains(Point point) => this._min <= point && this._max >= point;

  bool containsXY(num x, num y) => this.contains(new Point(x,y));

  bool containsBounds(Bounds bounds) => this.contains(bounds.topLeft) && this.contains(bounds.bottomRight);

  bool intersects(Bounds bounds) => this.contains(bounds.topLeft);

  bool overlaps(Bounds bounds){
    var br = bounds.bottomRight;
    return br.x > _min.x &&  br.x < _max.x
        && br.y > _min.y && br.y < _max.y;
  }
  bool get isValid => this._min != null && this._max != null;
}
