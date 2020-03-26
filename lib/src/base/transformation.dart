import 'point.dart' as p;

class Transformation {
  num _a;
  num _b;
  num _c;
  num _d;

  Transformation(this._a, this._b, this._c, this._d);

  p.Point transform(p.Point point, {double scale = 1.0}) =>
      new p.Point(
        scale * (this._a * point.x + this._b),
        scale * (this._c * point.y + this._d)
      );

  p.Point reverse(p.Point point, {double scale = 1.0}) =>
      new p.Point(
        (point.x / scale - this._b) / this._a,
        (point.y / scale - this._d) / this._c,
      );
}