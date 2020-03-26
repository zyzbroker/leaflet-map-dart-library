import 'dart:html';

import 'package:leaflet/src/utility/dom.dart' as dom;
import 'package:leaflet/src/lmap.dart';
import 'package:leaflet/src/utility/helper.dart' as h;
import 'package:leaflet/src/base/evented.dart';

import 'control.dart';
import 'zoom_options.dart';

typedef _fn(MouseEvent event);

class Zoom extends Control {
  AnchorElement _zoomInButton;
  AnchorElement _zoomOutButton;

  Zoom._([ZoomOptions options=null]):super(options){
    this._zoomInButton = null;
    this._zoomOutButton = null;
  }

  factory Zoom.create([String position='topleft']){
    ZoomOptions options = new ZoomOptions(position);
    return new Zoom._(options);
  }

  @override
  onAdd(LMap map) {
    this.map = map;
    map.zoomControl = this;
    String zoomName = 'leaflet-control-zoom';
    this.container = dom.createElement(tagName: 'div', className: zoomName + ' leaflet-bar');
    ZoomOptions options =this.options;

    this._zoomInButton = this._createButton(html: options.zoomInText,
      title: options.zoomInTitle, className: '$zoomName-in', container: this.container, fn: this._zoomIn);
    this._zoomOutButton = this._createButton(html: options.zoomOutText,
      title: options.zoomOutTitle, className: '$zoomName-out', container: this.container, fn: this._zoomOut);

    this._updateDisabled(this, null);
    map.on('zoomend zoomlevelchange', this._updateDisabled, this);
  }

  AnchorElement _createButton({String html, String title, String className, HtmlElement container, _fn fn}){
    AnchorElement link = dom.createElement(tagName: 'a', className: className, container: container);
    link.innerHtml = html;
    link.title = title;
    link.href = '#';
    link.setAttribute('role', 'button');
    link.setAttribute('aria-label', title);

    h.disableClickPropagation(link);
    link.onClick.listen(h.stop);
    link.onClick.listen(fn);
    link.onClick.listen(this.refocusOnMap);
    return link;
  }

  _zoomIn(MouseEvent event){
    LMap map = this.map;
    if(!this.disabled && map.zoom < map.maxZoom){
      var delta = map.options.zoomDelta * (event.shiftKey ? 3 : 1);
      map.setZoom(map.zoom + delta);
    }
  }

  _zoomOut(MouseEvent event){
    LMap map = this.map;
    if (!this.disabled && map.zoom > map.minZoom){
      var delta = map.options.zoomDelta * (event.shiftKey ? 3 : 1);
      map.setZoom(map.zoom - delta);
    }
  }

  disable(){
    this.disabled = true;
    this._updateDisabled(this, null);
  }

  enable(){
    this.disabled = false;
    this._updateDisabled(this,  null);
  }

  void _updateDisabled([dynamic context, AppEvent appEvent]){
    LMap map = this.map;
    if(map == null){
      return;
    }
    String className = 'leaflet-disabled';
    this._zoomInButton.classes.remove(className);
    this._zoomOutButton.classes.remove(className);

    if(this.disabled || map.zoom == map.minZoom){
      h.addClass(this._zoomOutButton, className);
    }
    if(this.disabled || map.zoom == map.maxZoom){
      h.addClass(this._zoomInButton, className);
    }
  }

  @override
  onRemove(LMap map) {
    map.off(types: 'zoomend zoomlevelchange',  fn: this._updateDisabled, context: this);
  }
}