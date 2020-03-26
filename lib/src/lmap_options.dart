import 'package:leaflet/src/base/crs.dart';
import 'package:leaflet/src/base/epsg3857.dart';
import 'package:leaflet/src/base/point.dart';
import 'package:leaflet/src/layers/layer.dart';
import 'package:leaflet/src/base/latlng_bounds.dart';
import 'package:leaflet/src/base/renderer.dart';

class LMapOptions {
  final CRS crs;
  Point center;
  num zoom;
  num minZoom;
  num maxZoom;
  List<Layer> layers;
  LatLngBounds maxBounds;
  num maxBoundsViscosity;
  Renderer renderer;
  bool zoomAnimation;
  num zoomAnimationThreshold;
  bool fadeAnimation;
  bool markerZoomAnimation;
  num transform3DLimit;
  num zoomSnap;
  num zoomDelta;
  bool trackResize;
  bool setView;
  bool tap;
  bool worldCopyJump;
  bool inertia;
  bool dragging;
  num easeLinearity;
  num inertiaDeceleration;
  num inertiaMaxSpeed;

  LMapOptions()
      : this.crs = new EPSG3857(),
        this.layers = <Layer>[],
        this.zoomAnimation = true,
        this.fadeAnimation = true,
        this.zoomAnimationThreshold = 4,
        this.markerZoomAnimation = true,
        this.transform3DLimit = 8388608,
        this.zoomSnap = 1,
        this.zoomDelta = 1,
        this.trackResize = true,
        this.setView = true,
        this.tap = false,
        this.minZoom = 1.0,
        this.maxBoundsViscosity = 0.0,
        this.inertia = true,
        this.easeLinearity = 0.2,
        this.dragging = true,
        this.inertiaMaxSpeed = double.infinity,
        this.inertiaDeceleration = 3400,
        this.worldCopyJump = false;
}
