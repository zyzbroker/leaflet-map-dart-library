import 'dart:html';

import 'package:leaflet/src/utility/dom.dart' as dom;
import 'lmap.dart';
import 'package:leaflet/src/controls/index.dart';


abstract class LMapControlBehavior{
  LMap _map;
  Attribution attributionControl;
  Zoom zoomControl;

  HtmlElement _controlContainer;
  Map<String, HtmlElement> _controlCorners;

  initControlBehavior(LMap map){
    this._map = map;
    this.attributionControl = null;
    this.zoomControl = null;
    this._controlCorners = <String, HtmlElement>{};
  }

  initControlPos() {
    this._controlCorners = <String, HtmlElement>{};
    this._controlContainer = dom.createElement(
        tagName: 'div',
        className: 'leaflet-control-container',
        container: this._map.container);
    this._controlCorners['topleft'] = this._createCorner('top', 'left');
    this._controlCorners['topright'] = this._createCorner('top', 'right');
    this._controlCorners['bottomleft'] = this._createCorner('bottom', 'left');
    this._controlCorners['bottomright'] = this._createCorner('bottom', 'right');
    new Attribution().addTo(this._map);
  }

  HtmlElement _createCorner(String vSide, String hSide) {
    var className = 'leaflet-$vSide leaflet-$hSide';
    return dom.createElement(
        tagName: 'div', className: className, container: this._controlContainer);
  }

  HtmlElement getControlCorner(String pos) => this._controlCorners[pos];

  addControl(Control ctl){
    ctl.addTo(this._map);
  }

  removeControl(Control ctl){
    ctl.remove();
  }


}