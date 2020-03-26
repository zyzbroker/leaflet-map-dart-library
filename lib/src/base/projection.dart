import 'latlng.dart';
import 'point.dart';
import 'bounds.dart';

abstract class Projection {
  Point project(LatLng latlng);
  LatLng unproject(Point point);
  Bounds get bounds;
}