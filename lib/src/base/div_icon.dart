import 'dart:html';

import 'icon.dart';
import 'icon_options.dart';
import 'point.dart' as p;
import 'package:leaflet/src/utility/dom.dart' as dom;

class DivIcon extends Icon {

  DivIcon(IconOptions options):super(options);

  factory DivIcon.withDefault() {
    var options = new IconOptions()
      ..className = 'leaflet-div-icon'
      ..iconSize = new p.Point(12, 12);
    return new DivIcon(options);
  }

  factory DivIcon.create(String className, String html, [List<num> pgPos = const <num>[]]) {
    var icon = new DivIcon.withDefault();
    icon.options.html = html;
    icon.options.className = '${icon.options.className} $className';
    if(pgPos.length == 2){
      icon.options.backgroundPosition = new p.Point(pgPos[0], pgPos[1]);
    }

    return icon;
  }

  @override
  HtmlElement createIcon(HtmlElement oldIcon) {
    var el = (oldIcon is DivElement) ? oldIcon : dom.createElement(tagName: 'div', className: this.options.className);

    el.setInnerHtml(this.options.html, validator: new DivIconNodeValidator());

    if (this.options.backgroundPosition != null){
      var pos = this.options.backgroundPosition;
      el.style.backgroundPosition = '${-pos.x}px ${-pos.y}px';
    }

    this.setIconStyles(el, 'icon');
    return el;
  }

  @override
  HtmlElement createShadow(HtmlElement oldIcon) {
    return null;
  }


}

class DivIconNodeValidator implements NodeValidator {
  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    return true;
  }
  @override
  bool allowsElement(Element element) {
    if(element is ScriptElement){
      return false;
    }
    return true;
  }
}

