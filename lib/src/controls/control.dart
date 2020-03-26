import 'dart:html';

import 'package:leaflet/src/lmap.dart';
import 'package:leaflet/src/utility/helper.dart' as h;
import 'package:leaflet/src/controls/control_options.dart';

abstract class Control {
  ControlOptions _options;
  LMap map;
  HtmlElement container;
  bool disabled;

  //child must implement these methods;
  onAdd(LMap map);
  onRemove(LMap map);

  Control([ControlOptions options = null]){
    this._options = h.setOrDefault(options, new ControlOptions());
    this.disabled = false;
    this.map = null;
    this.container = null;
  }

  ControlOptions get options => this._options;

  addTo(LMap map){
    try {
      this.map = map;
      this.remove();
      this.onAdd(map);

      var pos = this._options.position,
          corner = map.getControlCorner(pos);
      h.addClass(this.container, 'leaflet-control');
      if (pos.indexOf('bottom') != -1) {
        corner.insertBefore(this.container, corner.firstChild);
      } else {
        corner.append(this.container);
      }
    } catch(ex){
      h.dumpError(ex);
    }
  }

  String get position => this._options.position;
  set position(String pos) {
    var map = this.map;

    if (map != null){
      map.removeControl(this);
    }

    this._options.position = pos;

    if(map != null){
      map.addControl(this);
    }
  }

  void remove(){
    if(this.map != null){
      this.onRemove(this.map);
      this.map = null;
    }
    if(this.container != null){
      this.container.remove();
    }
  }

  void refocusOnMap(Event e){
    if (this.map != null){
      if (e is MouseEvent
          && e.screen.x > 0
          && e.screen.y > 0 ){
        this.map.container.focus();
      }
    }
  }
}