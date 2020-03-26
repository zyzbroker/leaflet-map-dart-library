import 'dart:html';

import 'package:leaflet/src/base/point.dart' as p;

class ImageLevel {
  HtmlElement element;
  num zoom;
  p.Point origin;

  String toString() => 'zoom:$zoom, point:${origin.toString()}, el: ${element.outerHtml}';
}