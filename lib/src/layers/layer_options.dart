import 'package:leaflet/src/base/latlng_bounds.dart';
import 'package:leaflet/src/utility/helper.dart' as h;

class LayerOptions {
  String attribution;
  bool bubblingMouseEvents = true;
  bool updateWhenIdle = false;
  num tileSize = 256;
  num opacity = 1;
  num zIndex = 1;
  num minZoom = 0.0;
  num maxZoom;
  num maxNativeZoom;
  num minNativeZoom = 0.0;
  num updateInterval = 200;
  num zoomOffset = 0;
  num keepBuffer = 2;
  bool detectRetina;
  bool tms = false;
  bool zoomReverse = false;
  bool noWrap = false;
  bool crossOrigin;
  bool updateWhenZooming = true;
  String pane = 'overlayPane';
  String errorTileUrl;
  List<String> subDomains;
  Map<String, String> customData;
  LatLngBounds bounds;
  String className = '';

  LayerOptions();

  LayerOptions.tileDefault() {
    this.pane = 'tilePane';
    this.minZoom = 0.0;
    this.maxZoom = 18.0;
    this.subDomains = ['a', 'b', 'c'];
  }

  LayerOptions.layerDefault() {
    this.pane = 'overlayPane';
  }

  Map<String, String> toMap() {
    Map<String, String> data = <String, String>{};
    data['pane'] = this.pane;
    data['minZoom'] = this.minZoom.toString();
    data['maxZoom'] = h.setOrDefault(this.maxZoom, '').toString();
    return data;
  }
}
