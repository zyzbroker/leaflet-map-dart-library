import 'dart:html';
import 'package:quiver/strings.dart' as str;

import 'layer_options.dart';
import 'package:leaflet/src/lmap.dart';
import 'package:leaflet/src/base/evented.dart';
import 'package:leaflet/src/utility/helper.dart' as h;

abstract class Layer extends Evented {
  LMap map;
  LMap mapToAdd;
  HtmlElement container;
  bool zoomAnimated;
  bool _hasClickHandler = false;
  dynamic customData;

  //child need to override
  Map<String, EventFunc> getEvents();
  beforeAdd(LMap map);
  onAdd(LMap map);
  onRemove(LMap map);

  LayerOptions options;
  Layer(this.options): super();

  addTo(LMap map) {
    this.map = map;
    this.zoomAnimated = map.zoomAnimated;
    map.addLayer(this);
  }

  remove(){
    if(this.map != null){
      this.map.removeLayer(this);
    }
  }

  removeFrom(LMap mapObj){

    if (mapObj != null){
      mapObj.removeLayer(this);
    }
  }

  HtmlElement getPane([String name]) {
    return this.map.getPane(str.isNotEmpty(name) ? name: this.options.pane);
  }

  String get attribution => this.options.attribution;

  void layerAdd([dynamic self, AppEvent appEvent]){
    var map = appEvent.target;
    if(!map.hasLayer(this)){
      print('--map has no this layer--');
      return;
    }

    try{
      var events = this.getEvents();

      void rstOnRemove([dynamic context, AppEvent appEvent]){
        map.off(types: events, context: this);
      }

      map.on(events, null, this);
      this.once('remove', rstOnRemove, this);
      this.onAdd(map);

      if(str.isNotEmpty(this.attribution) && map.attributionControl != null){
        map.attributionControl.addAttribution(this.attribution);
      }

      this.fire('add');
      map.fire('layeradd',new EventData(map,{'layer': this}));
    } catch(e){
      h.dumpError(e);
    }

  }

  addInteractiveTarget(HtmlElement el){
    this.map.addInteractiveTarget(el);
  }

  removeInteractiveTarget(HtmlElement el){
    this.map.removeInteractiveTarget(el);
  }

  addClickHandler(EventFunc clickHandler){
    if(!this._hasClickHandler){
      this._hasClickHandler = true;
      this.on('click', clickHandler, this);
    }
  }

  removeClickHandler(EventFunc clickHandler){
    if(this._hasClickHandler){
      this.off(types: 'click',context:  this, fn: clickHandler);
      this._hasClickHandler = false;
    }
  }

}