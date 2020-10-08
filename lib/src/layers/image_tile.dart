import 'dart:html';
import 'dart:async';
import 'package:leaflet_map/src/base/point.dart' as p;

class ImageTile {
  HtmlElement element;
  bool current = false;
  bool active = false;
  bool retain = false;
  DateTime loadedTime;
  p.Point coords;

  StreamSubscription<Event> onLoadSubscription;
  StreamSubscription<Event> onErrorSubscription;

  ImageTile(this.element, this.coords, this.current);
}