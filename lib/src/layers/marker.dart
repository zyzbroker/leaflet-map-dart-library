import 'dart:html';
import 'dart:async';

import 'package:quiver/strings.dart' as str;

import 'marker_options.dart';
import 'layer.dart';
import 'package:leaflet_map/src/base/latlng.dart';
import 'package:leaflet_map/src/base/point.dart' as p;
import 'package:leaflet_map/src/base/icon.dart';
import 'package:leaflet_map/src/base/evented.dart';
import 'package:leaflet_map/src/lmap.dart';
import 'package:leaflet_map/src/utility/helper.dart' as h;

typedef void OnMarkerClick(dynamic customData);

class Marker extends Layer {
  LatLng _latlng;
  HtmlElement _icon = null;
  HtmlElement _shadow = null;
  OnMarkerClick _onClick;
  StreamSubscription<Event> _onClickSubscription;

  Marker(List<double> latlng, [MarkerOptions options = null]): super(options) {
    if(options == null){
      super.options = new MarkerOptions();
    }
    this._latlng = h.toLatLng(latlng);
  }

  set onMarkerClick(OnMarkerClick onClick) {
    this._onClick = onClick;
  }

  void _markerClick([dynamic context, AppEvent appEvent]) {
    if(this._onClick != null) {
      this._onClick(this.customData);
    }
  }

  MarkerOptions get markerOptions => this.options;

  LatLng getLatLng() => this._latlng;
  setLatLng(List<double> value){
    var oldLatLng = this._latlng;
    this._latlng = h.toLatLng(value);
    this.update();
    this.fire('move', new EventData(this,{
      'oldLatLng': oldLatLng,
      'latlng': this._latlng}));
  }

  set zIndexOffset(num offset) {
    var options = this.markerOptions;
    options.zIndexOffset = offset;
    this.update();
  }

  set icon(Icon value) {
    var options = this.markerOptions;
    options.icon = value;

    if(this.map != null){
      this._initIcon();
      this.update();
    }
    //tood: popup binding with this marker
  }

  HtmlElement getIcon() => this._icon;

  Map<String, EventFunc> getEvents(){
    return <String, EventFunc> {
      'zoom': this.update,
      'viewreset': this.update
    };
  }

  @override
  void onRemove(LMap map){
    if(this.zoomAnimated){
      map.off(types:  'zoomanim', fn:  this._animateZoom, context:  this);
    }
    this._removeIcon();
    this._removeShadow();
  }

  void _removeIcon(){
    if(this.markerOptions.riseOnHover){
      this.off(types: {
        'mouseover': this._bringToFront,
        'mouseout': this._bringToBack
      }, context: this);
    }
   this._unbindClickEvent();
    this._icon.remove();
    this.removeInteractiveTarget(this._icon);
    this._icon = null;
  }

  void _unbindClickEvent(){
    this.removeClickHandler(this._markerClick);
    if(this._onClickSubscription != null){
      this._onClickSubscription.cancel();
      this._onClickSubscription = null;
    }
  }

  void _bringToFront([dynamic context, AppEvent appEvent]){
    this._updateZIndex(this.markerOptions.riseOffset);
  }

  void _bringToBack([dynamic context, AppEvent appEvent]){
    this._updateZIndex(0);
  }

  num _zIndex = 0;

  _updateZIndex(num offset){
    var index = this._zIndex + offset;
    this._icon.style.zIndex = '$index';
  }

  void _removeShadow(){
    if(this._shadow != null){
      this._shadow.remove();
    }
    this._shadow = null;
  }

  @override
  void beforeAdd(LMap map){
    this.map = map;
  }

  @override
  void onAdd(LMap map){

    this.zoomAnimated = map.options.zoomAnimation;
    if(this.zoomAnimated){
      map.on('zoomanim', this._animateZoom, this);
    }

    try{
      this._initEvents();
      this._initIcon();
      this.update();
    } catch(ex){
      h.dumpError(ex);
    }
  }

  void _initEvents(){
    if(this._onClick != null){
      this.addClickHandler(this._markerClick);
    }
  }

  void _animateZoom([dynamic context, AppEvent appEvent]){
    if(appEvent == null || appEvent.eventData == null ||
    appEvent.eventData.data == null){
      return;
    }
    var data = appEvent.eventData.data as Map<String,dynamic>;
    var pos = this.map.latLngToNewLayerPoint(this._latlng, data['zoom'], data['center']);
    this._setPosition(pos);
  }

  void _initIcon(){
    String classToAdd = 'leaflet-zoom-' + (this.zoomAnimated ? 'animated' : 'hide');
    this._icon = this._createIcon(classToAdd);
    this._shadow = this._createShadow(classToAdd);
    this._initInteraction();
  }

  HtmlElement _createShadow(String classToAdd){
    var options = this.markerOptions,
    classToAdd = 'leaflet-zoom-' + (this.zoomAnimated ? 'animated' : 'hide');
    var shadow = options.icon.createShadow(this._shadow) as ImageElement,
      addShadow = false;

    if(shadow != this._shadow){
      addShadow = true;
      this._removeShadow();
    }
    if(shadow != null){
      h.addClass(shadow,classToAdd);
      shadow.alt = '';
    }

    if (options.opacity < 1){
      h.setOpacity(shadow, options.opacity);
    }

    this._shadow = shadow;

    if(addShadow){
      this.getPane('shadowPane').append(shadow);
    }

    return shadow;
  }


  _initInteraction(){
    if(!this.markerOptions.interactive) {
      return;
    }
    h.addClass(this._icon, 'leaflet-interactive');

    if(this._onClickSubscription == null){
      this._onClickSubscription = this._icon.onClick.listen((MouseEvent evt){
        evt.preventDefault();
        evt.stopPropagation();
        this.fire('click', new EventData(this));
      });
    }

    this.addInteractiveTarget(this._icon);
    //todo: add dragging capability
  }

  HtmlElement _createIcon(String classToAdd){
    var options = this.markerOptions;
    var icon = options.icon.createIcon(this._icon),
        addIcon = false;
    if(icon != this._icon){
      if(this._icon != null){
        this._removeIcon();
      }
      addIcon = true;

      if(str.isNotEmpty(options.title)){
        icon.title = options.title;
      }
      if(icon is ImageElement){
        icon.alt = h.setOrDefault(options.alt, '');
      }
    }

    h.addClass(icon, classToAdd);

    if(options.keyboard){
      icon.tabIndex = 0;
    }

    if(options.opacity < 1){
      h.setOpacity(icon, options.opacity);
    }

    if(addIcon){
      this.getPane().append(icon);
    }

    return icon;
  }

  List<double> get latlng => h.latLngToList(this._latlng);

  set latlng(List<double> latlng){
    LatLng old = this._latlng;
    this._latlng = h.toLatLng(latlng);
    this.update();

    EventData evtData = new EventData(this)
      ..data = {'old': old, 'new': this._latlng};

    this.fire('move', evtData);
  }

  void update([dynamic context, AppEvent appEvent]){
    if(this._icon != null && this.map != null){
      var pos = this.map.latLngToLayerPoint(this._latlng).round();
      this._setPosition(pos);
    }
  }

  _setPosition(p.Point pos){
    h.setPosition(this._icon, pos);

    if(this._shadow != null){
      h.setPosition(this._shadow, pos);
    }

    this._zIndex = pos.y + this.markerOptions.zIndexOffset;
    this._resetZIndex();
  }

  _resetZIndex(){
    this._updateZIndex(0);
  }

  p.Point get popupAnchor => this.markerOptions.icon.options.popupAnchor;
  p.Point get tooltipAnchor => this.markerOptions.icon.options.tooltipAnchor;

}