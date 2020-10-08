import 'dart:html';
import 'dart:math' as math;
import 'dart:async';

import 'package:quiver/strings.dart' as str;
import 'package:tuple/tuple.dart';

import 'layer.dart';
import 'package:leaflet_map/src/base/latlng.dart';
import 'layer_options.dart';
import 'package:leaflet_map/src/base/point.dart' as p;
import 'package:leaflet_map/src/base/latlng_bounds.dart';
import 'image_tile.dart';
import 'image_level.dart';
import 'package:leaflet_map/src/base/bounds.dart';
import 'package:leaflet_map/src/lmap.dart';
import 'package:leaflet_map/src/utility/helper.dart' as h;
import 'package:leaflet_map/src/utility/dom.dart' as dom;
import 'package:leaflet_map/src/base/evented.dart';
import 'package:leaflet_map/src/utility/throttle.dart' as t;

typedef T MathMaxMinFunc<T extends num>(T a, T b);

abstract class GridLayer extends Layer {
  num _tileZoom;
  num _fadeFrame;
  bool _loading = false;
  bool _noPrune = false;
  Map<num, ImageLevel> _levels;
  ImageLevel _level;
  Map<String,ImageTile> _tiles;

  GridLayer(LayerOptions options):super(options){
    this.options = h.setOrDefault(options, new LayerOptions.tileDefault());
    this._levels = <num, ImageLevel>{};
    this._tiles = <String,ImageTile>{};
  }

  //override by child class
  HtmlElement createTile(p.Point coords);

  abortLoading(){
    ImageTile tile;
    List<String> clonedKeys = this._tiles.keys.toList();
    for(var key in clonedKeys){
      tile = this._tiles[key];
      if(tile.coords.z != this._tileZoom){
        ImageElement el = tile.element as ImageElement;
        this._removeTileEvents(tile);
        if(!el.complete){
          el.src = h.emptyImageUrl;
          el.remove();
          this._tiles.remove(key);
        }
      }
    }
  }

  bool get loading => _loading;
  num get tileZoom => this._tileZoom;

  onAdd(LMap map){
    this._initContainer();
    this._tiles = <String, ImageTile>{};
    this._levels = <num, ImageLevel>{};
    this._resetView();
    this._update();
  }

  beforeAdd(LMap map){
    map.addZoomLimit(this);
  }

  onRemove(LMap map){
    this._removeAllTiles();
    this.container.remove();
    map.removeZoomLimit(this);
    this.container = null;
    this._tileZoom =  null;
  }

  bringToFront(){
    if(this.map != null){
      h.toFront(this.container);
      this._setAutoZIndex(math.max);
    }
  }

  bringToBack(){
    if(this.map != null){
      h.toBack(this.container);
      this._setAutoZIndex(math.min);
    }
  }

  setOpacity(num opacity){
    this.options.opacity = opacity;
    this._updateOpacity();
  }

  setZIndex(num zIndex){
    this.options.zIndex = zIndex;
    this._updateZIndex();
  }

  redraw(){
    if(this.map != null){
      this._removeAllTiles();
      this._update();
    }
  }

  _setAutoZIndex(MathMaxMinFunc compare){
    var layers = this.getPane().children,
       edgeZIndex = -compare(double.negativeInfinity, double.infinity);

    String zIndex;

    for(HtmlElement l in layers){
      zIndex = l.style.zIndex;
      if(l != this.container && str.isNotEmpty(zIndex)){
        edgeZIndex = compare(edgeZIndex, int.parse(zIndex));
      }
    }

    if(edgeZIndex.isFinite){
      this.options.zIndex = edgeZIndex + compare(-1, 1);
      this._updateZIndex();
    }
  }

  _updateZIndex(){
    if (this.container != null && this.options.zIndex != null){
      this.container.style.zIndex = this.options.zIndex.toString();
    }
  }

  _removeAllTiles(){
    var clonedKeys = this._tiles.keys.toList();
    for(String key in clonedKeys){
      this._removeTile(key);
    }
  }

  _removeTile(String key){
    var tile = this._tiles[key];
    if(tile == null){
      return;
    }
    tile.element.remove();
    this._tiles.remove(key);

    this.fire('tileunload',new EventData(this, {
      'tile': tile,
      'coords': this._keyToTileCoords(key)
    }));
  }

  _keyToTileCoords(String key){
    var k = key.split(':');
    p.Point coords = new p.Point.fromString(key, ':');
    coords.z = int.parse(k[2]);
    return coords;
  }

  _initContainer(){
    if(this.container != null){
      return;
    }

    String className = 'leaflet-layer' + h.setOrDefault(this.options.className, '');
    this.container = dom.createElement(tagName: 'div', className: className);
    this._updateZIndex();

    if(this.options.opacity < 1){
      this._updateOpacity();
    }

    this.getPane().append(this.container);
  }

  _updateOpacity([num highResTime]){

    if(this.map == null){
      return;
    }
   try {
     h.setOpacity(this.container, this.options.opacity);

     var now = new DateTime.now(),
         nextFrame = false,
         willPrune = false;
     for (ImageTile tile in this._tiles.values) {
       if (tile.current == false || tile.loadedTime == null) {
         continue;
       }
       var fade = math.min(1, now
           .difference(tile.loadedTime)
           .inMilliseconds / 200);
       h.setOpacity(tile.element, fade);

       if (fade < 1) {
         nextFrame = true;
       } else {
         if (tile.active) {
           willPrune = true;
         } else {
           this._onOpaqueTile(tile);
         }
         tile.active = true;
       }
     }

     if (willPrune && this._noPrune != true) {
       this._pruneTiles();
     }

     if (nextFrame) {
       h.cancelAnimFrame(this._fadeFrame);
       this._fadeFrame = h.requestAnimFrame(this._updateOpacity);
     }
   } catch (ex){
      h.dumpError(ex);
   }
  }

  _pruneTiles(){

    if(this.map == null){
      return;
    }

    if(this._removeTilesIfMapZoomOutOfBound()){
      return;
    }
    this._retainCurrentTiles();
    this._retainParentsAndChildren();
    this._removeNotRetainedTiles();
  }

  _retainParentsAndChildren(){
    var clonedKeys = this._tiles.keys.toList();

    for(var key in clonedKeys){
      var tile = this._tiles[key];
      if(tile.current == true && tile.active != true){
        var coords = tile.coords;
        if(!this._retainParent(coords.x, coords.y, coords.z, coords.z - 5)){
          this._retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }
  }

  bool _retainParent(num x, num y, num z, num minZoom){
    var x2 = (x / 2 ).floor(),
      y2 = (y / 2).floor(),
      z2 = z - 1,
      coords2 = new p.Point(x2, y2);
    coords2.z = z2;

    var key = this._tileCoordsToKey(coords2);

    if(this._tiles.containsKey(key)){
      var tile = this._tiles[key];
      if(tile.active){
        tile.retain = true;
      } else if (tile.loadedTime !=  null){
        tile.retain = true;
      }
    }

    if(z2 > minZoom){
      return this._retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  _retainChildren(num x, num y, num z, num maxZoom){
    var x2 = x * 2, y2 = y * 2;
    var key, coords;

    for(var i = x2; i < x2 + 2; i++){
      for(var j = y2; j < y2 + 2; j++){
        coords = new p.Point(i,j);
        coords.z = z + 1;
        key = this._tileCoordsToKey(coords);
        if(this._tiles.containsKey(key)){
          var tile = this._tiles[key];
          if(tile.active){
            tile.retain = true;
            continue;
          } else if (tile.loadedTime != null){
            tile.retain = true;
          }
        }
        if (z + 1 < maxZoom){
          this._retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  _removeNotRetainedTiles(){
    var clonedKeys = this._tiles.keys.toList();
    for(var key in clonedKeys){
      if(!this._tiles[key].retain){
        this._removeTile(key);
      }
    }
  }

  bool _removeTilesIfMapZoomOutOfBound(){
    var zoom = this.map.zoom;
    if(zoom > this.options.maxZoom || zoom < this.options.minZoom){
      this._removeAllTiles();
      return true;
    }
    return false;
  }

  _retainCurrentTiles(){
    List<String> cloneKeys = this._tiles.keys.toList();

    for(var key in cloneKeys){
      var tile = this._tiles[key];
      tile.retain = tile.current;
    }
  }

  _onOpaqueTile(ImageTile tile){}


  _update([List<double> center]){

    if (this.map ==  null){
      return;
    }

    var zoom = this.clampZoom(map.zoom);
    center = h.setOrDefault(center, map.getCenter());
    if(this._tileZoom == null){
      return;
    }

    var pixelBounds = this._getTiledPixelBounds(center),
      tileRange = this._pxBoundsToTileRange(pixelBounds),
      tileCenter = tileRange.center,
      queue = <p.Point>[],
      margin = this.options.keepBuffer,
      noPruneRange = new Bounds.fromPoints([
        tileRange.bottomLeft - new p.Point(margin, -margin),
        tileRange.topRight + new p.Point(margin, -margin),
      ]);

    if(!tileRange.min.x.isFinite || !tileRange.min.y.isFinite
      || !tileRange.max.x.isFinite || !tileRange.max.y.isFinite){

      throw new ArgumentError('Can not load an infinite number of tiles');
    }

    var clonedKeys = this._tiles.keys.toList();
    for(var key in clonedKeys){
      var tile = this._tiles[key];
      var c = tile.coords;
      if(c.z != this._tileZoom || !noPruneRange.contains(new p.Point(c.x, c.y))){
        tile.current = false;
      }
    }

    if((zoom - this._tileZoom).abs() > 1){
      this.setView(center, zoom);
      return;
    }

    for(var j = tileRange.min.y; j <= tileRange.max.y; j++){
      for(var i= tileRange.min.x; i <= tileRange.max.x; i++){
        var coords = new p.Point(i,j);
        coords.z = this._tileZoom;
        if(!this._isValidTile(coords)){
          continue;
        }
        var tile = this._tiles[this._tileCoordsToKey(coords)];
        if(tile != null){
          tile.current = true;
        }
          queue.add(coords);
      }
    }
    if(queue.isNotEmpty){
      queue.sort((a,b) => (a.distanceTo(tileCenter).compareTo(b.distanceTo(tileCenter))));

      if(this._loading != true){
        this._loading =true;
        this.fire('loading');
      }

      var fragment = document.createDocumentFragment();
      for(var coords in queue){
        this._addTile(coords, fragment);
      }
      this._level.element.append(fragment);
    }
  }

  _addTile(p.Point coords, DocumentFragment fragment){
    var tilePos = this._getTilePos(coords),
      key = this._tileCoordsToKey(coords);
    var el = this.createTile(this._wrapCoords(coords));

    this._initTile(el);
    h.setPosition(el, tilePos);

    var tile = new ImageTile(el, coords, true);
    this._tiles[key] = tile;
    this._attachTileEvents(tile);
    fragment.append(el);

    this.fire('tileloadstart', new EventData(this, tile));
  }

  _attachTileEvents(ImageTile tile){
    ImageElement el = tile.element as ImageElement;

    _tileOnLoad(Event evt){
      this.onTileReady(tile);
    }

    _tileOnError(Event evt){
      String errUrl = this.options.errorTileUrl;
      if (str.isNotEmpty(errUrl) && el.src != errUrl){
        el.src = errUrl;
      }
      this.onTileReady(tile, 'failed to load image');
    }

    tile.onLoadSubscription = el.onLoad.listen(_tileOnLoad);
    tile.onErrorSubscription = el.onError.listen(_tileOnError);
  }

  _removeTileEvents(ImageTile tile){
    if(tile.onLoadSubscription != null){
      tile.onLoadSubscription.cancel();
    }
    if(tile.onErrorSubscription != null){
      tile.onErrorSubscription.cancel();
    }
  }

  _initTile(HtmlElement tile){
    tile.classes.add('leaflet-tile');
    var tileSize = this.getTileSize();
    tile.style.width = '${tileSize.x}px';
    tile.style.height = '${tileSize.y}px';

    if(h.android && !h.android23){
      tile.style.backfaceVisibility = 'hidden';
    }
  }

  // called by child when tile is created
  Timer _timer;
  onTileReady(ImageTile tile, [String err='']){
    if(this.map == null){
      return;
    }

    bool hasError = str.isNotEmpty(err);

    try{
      if(hasError){
        this.fire('tileerror', new EventData(this, {
          'error': err,
          'tile': tile.element,
          'coords': tile.coords
        }));
      }

      var key = this._tileCoordsToKey(tile.coords);
      if(!this._tiles.containsKey(key)){
        return;
      }

      tile.loadedTime = new DateTime.now();

      if(this.map.wantToFadeAnimation){
        h.setOpacity(tile.element, 0.0);
        if(this._fadeFrame != null){
          h.cancelAnimFrame(this._fadeFrame);
        }
        this._fadeFrame = h.requestAnimFrame(this._updateOpacity);
      } else {
        tile.active = true;
        this._pruneTiles();
      }

      if(!hasError){
        tile.element.classes.add('leaflet-tile-loaded');
        this.fire('tileload', new EventData(this, {
          'tile': tile.element,
          'coords': tile.coords}
        ));
      }

      if(this._noTilesToLoad()){
        this._loading = false;
        this.fire('load');
        this._timer = new Timer(new Duration(milliseconds: 250), this._pruneTiles);
      }
    } catch(ex){
      h.dumpError(ex);
    }
  }

  bool _noTilesToLoad(){
    for(var tile in this._tiles.values){
      if(tile.loadedTime == null){
        return false;
      }
    }
    return true;
  }

  Tuple2<num, num> _wrapX;
  Tuple2<num, num> _wrapY;
  p.Point _tileSize;
  Bounds _globalTileRange;
  Bounds get globalTileRange => this._globalTileRange;
  
  _resetGrid(){
    num x1, x2;
    var crs = this.map.options.crs;
    this._tileSize = this.getTileSize();
    var bounds = this.map.getPixelWorldBounds(this._tileZoom);
    this._globalTileRange = this._pxBoundsToTileRange(bounds);


    if(crs.wrapLng == null || this.options.noWrap == true) {
      this._wrapX = null;
    } else {
        x1 = (this.map.project(h.toLatLng([0.0, crs.wrapLng.item1]), this._tileZoom).x /
            this._tileSize.x).floor();
        x2 = (this.map.project(h.toLatLng([0.0, crs.wrapLng.item2]), this._tileZoom).x /
          this._tileSize.y).ceil();
        this._wrapX = new Tuple2(x1, x2);
    }

    if(crs.wrapLat == null || this.options.noWrap == true){
      this._wrapY = null;
    } else {
      x1 = (this.map.project(h.toLatLng([crs.wrapLat.item1,0.0]), this._tileZoom).y
          / this._tileSize.x).floorToDouble();
      x2 = (this.map.project(h.toLatLng([crs.wrapLat.item2,0.0]), this._tileZoom).y
        / this._tileSize.y).ceilToDouble();
      this._wrapY = new Tuple2(x1, x2);
    }

  }

  p.Point _wrapCoords(p.Point coords){
    var newCoords = new p.Point(
      this._wrapX != null ? h.wrapNum(coords.x, this._wrapX) : coords.x,
      this._wrapY != null ? h.wrapNum(coords.y, this._wrapY) : coords.y,
      );
    newCoords.z = coords.z;
    return newCoords;
  }

  p.Point _getTilePos(p.Point coords) =>
    coords.scaleBy(this.getTileSize()) - this._level.origin;

  p.Point getTileSize() => new p.Point(this.options.tileSize, this.options.tileSize);

  String _tileCoordsToKey(p.Point coords){
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  bool _isValidTile(p.Point coords){
    var crs = this.map.options.crs;
    if(crs.infinite != true){
      var bounds = this._globalTileRange;
      if((crs.wrapLng == null && (coords.x < bounds.min.x
        || coords.x > bounds.max.x))
          || (crs.wrapLat == null &&(coords.y < bounds.min.y
          || coords.y > bounds.max.y))){
        return false;
      }
    }
    if (this.options.bounds == null){
      return true;
    }

    var tileBounds = this._tileCoordstoBounds(coords);
    return h.boundsToLatLngBounds(this.options.bounds).overlaps(tileBounds);
  }

  List<LatLng> _tileCoordsToNwSe(p.Point coords){
    var map = this.map,
      tileSize = this.getTileSize(),
      nwPoint = coords.scaleBy(tileSize),
      sePoint = nwPoint + tileSize,
      nw = map.unproject(nwPoint,coords.z),
      se = map.unproject(sePoint, coords.z);
    return [nw, se];
  }

  LatLngBounds _tileCoordstoBounds(p.Point coords){
    var bp = this._tileCoordsToNwSe(coords),
      bounds = new LatLngBounds.fromCorners(bp[0], bp[1]);
    if(this.options.noWrap != true){
      bounds = this.map.wrapLatLngBounds(bounds);
    }
    return bounds;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds){
    var tileSize = this.getTileSize();
    return new Bounds.fromPoints([
      bounds.min.unScaleBy(tileSize).floor(),
      bounds.max.unScaleBy(tileSize).ceil()
    ]);
  }

  Bounds _getTiledPixelBounds(List<double> center){
    var map = this.map,
      mapZoom = map.animationZoom != null
        ? math.max(map.animationZoom, map.zoom)
          : map.zoom,
      scale = map.getZoomScale(mapZoom, this._tileZoom),
      pixelCenter = map.project(h.toLatLng(center), this._tileZoom).floor(),
      halfSize = map.getSize() / (scale * 2);

    return new Bounds.fromPoints([
        pixelCenter - halfSize,
        pixelCenter + halfSize]
    );
  }

  t.Throttle _onMoveThrottle;

  Map<String, EventFunc> getEvents(){
    var events = <String, EventFunc>{};
    events['viewprereset'] = this._invalidateAll;
    events['viewreset'] = this._resetView;
    events['zoom'] = this._resetView;
    events['moveend'] = this._onMoveEnd;

    if(this.options.updateWhenIdle != true){
      if (this._onMoveThrottle == null){
        this._onMoveThrottle = new t.Throttle(this._onMoveEnd, this.options.updateInterval);
      }
      events['move'] = this._onMoveThrottle.run;
    }
    events['zoomanim'] = this._animateZoom;

    return events;
  }

  void _invalidateAll([dynamic context, AppEvent appEvent]){
    var clonedKeys = this._levels.keys.toList();
    for(var z in clonedKeys){
      this._levels[z].element.remove();
      this._onRemoveLevel(z);
      this._levels.remove(z);
    }
    this._removeAllTiles();
    this._tileZoom = null;
  }

  _onRemoveLevel([num zoom]){}
  _onUpdateLevel([num zoom]){}
  _onCreateLevel([num zoom]){}

  void _onMoveEnd([dynamic context, AppEvent appEvent]){
    if (this.map == null || this.map.animationZoom == true){
      return;
    }
    this._update();
  }

  void _animateZoom([dynamic context, AppEvent appEvent]){
    if(appEvent == null || appEvent.eventData == null ||
        appEvent.eventData.data == null){
      return;
    }

    var e = appEvent.eventData.data as Map<String, dynamic>;
    List<double> center = h.parseT<List<double>>(e['center']);
    num zoom  = h.parseT<num>(e['zoom']);
    bool noUpdate = h.setOrDefault(e['noUpdate'], false);
    if(center == null || zoom == null){
      return;
    }
    this.setView(center, zoom, true, noUpdate);
  }


  void _resetView([dynamic context, AppEvent appEvent]) {
    var animating = context != null && context is Map<String,bool> && (context['pinch'] || context['flyTo']);
    this.setView(this.map.getCenter(), this.map.zoom, animating, animating);
  }

  setView(List<double> center, double zoom, [bool noPrune = false, bool noUpdate = false]){
    var tileZoom = this.clampZoom(zoom);
    if((this.options.maxZoom != null &&
      tileZoom > this.options.maxZoom)
        || (this.options.minZoom != null &&
        tileZoom < this.options.minZoom)){
      tileZoom =  null;
    }
    var tileZoomChanged = this.options.updateWhenZooming == true
      && (tileZoom != this._tileZoom);

    if(noUpdate == false || tileZoomChanged == true){
      this._tileZoom = tileZoom;
      this.abortLoading();

      this._updateLevels();
      this._resetGrid();
      if(tileZoom != null){
        this._update(center);
      }

      if(!noPrune){
        this._pruneTiles();
      }
      this._noPrune = !!noPrune;
    }
    this._setZoomTransforms(center, zoom);
  }

  _updateLevels(){
    var zoom = this._tileZoom,
      maxZoom = this.options.maxZoom;

    if(zoom == null){
      return;
    }

    ImageLevel level;
    List<num> clonedKeys = this._levels.keys.toList();

    for(var z in clonedKeys){
      level = this._levels[z];
      if(level.element.children.isNotEmpty || z == zoom){
        level.element.style.zIndex =  (maxZoom - (zoom - z).abs()).toString();
        this._onUpdateLevel(z);
      } else {
        level.element.remove();
        this._removeTileAtZoom(z);
        this._levels.remove(z);
      }
    }

    level = this._levels[zoom];
    var map = this.map;
    if(level == null){
      level = new ImageLevel();
      this._levels[zoom] = level;
      level.element = dom.createElement(tagName: 'div', className: 'leaflet-tile-container leaflet-zoom-animated',
        container: this.container);
      level.element.style.zIndex = maxZoom.toString();
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom).round();
      level.zoom = zoom;
      this._setZoomTransform(level, map.getCenter(), map.zoom);
      this._onCreateLevel(zoom);
    }

    this._level = level;
    return;
  }

  _removeTileAtZoom(num zoom){
    List<String> keys = <String>[];
    List<String> clonedKeys = this._tiles.keys.toList();
    for(var key in clonedKeys){
      if(this._tiles[key].coords.z == zoom){
        this._tiles.remove(key);
      }
    }
  }

  _setZoomTransforms(List<double> center, double zoom){
    List<num> clonedKeys = this._levels.keys.toList();
    for(var key in clonedKeys){
      var level = this._levels[key];
      this._setZoomTransform(level, center, zoom);
    }
  }

  _setZoomTransform(ImageLevel level, List<double> center, double zoom){
    var scale = this.map.getZoomScale(zoom, level.zoom),
      translate = (level.origin * scale - this.map.getNewPixelOrigin(center, zoom)).round();
    h.setTransform(level.element, translate, scale);
  }

  double clampZoom(double zoom) => zoom;


}