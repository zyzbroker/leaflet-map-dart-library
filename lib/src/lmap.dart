import 'dart:html';
import 'dart:math' as math;
import 'dart:async';
import 'package:quiver/strings.dart' as str;
import 'package:tuple/tuple.dart';

import 'package:leaflet_map/src/base/pos_animation.dart';
import 'lmap_options.dart';
import 'package:leaflet_map/src/base/latlng.dart';
import 'package:leaflet_map/src/base/crs.dart';
import 'package:leaflet_map/src/utility/helper.dart' as h;
import 'package:leaflet_map/src/base/point.dart' as p;
import 'package:leaflet_map/src/base/evented.dart';
import 'package:leaflet_map/src/base/latlng_bounds.dart';
import 'package:leaflet_map/src/base/bounds.dart';

import 'lmap_layer_behavior.dart';
import 'lmap_control_behavior.dart';
import 'lmap_drag_behavior.dart';

class LMap extends Evented with LMapLayerBehavior, LMapControlBehavior, LMapDragBehavior {
  double _zoom;
  HtmlElement _container;
  String _containerId;
  bool _fadeAnimated;
  Map<String, HtmlElement> _panes;
  HtmlElement _mapPane;

  p.Point _size;
  bool _sizeChanged;
  bool _loaded = false;
  bool _animatingZoom = false;
  bool _zoomAnimated;
  List<double> _lastCenter;
  p.Point _pixelOrigin;
  List<double> _animateToCenter;
  double _animateToZoom;
  Timer _sizeTimer;
  num _flyToFrame;
  PosAnimation _panAnim;
  double _layersMaxZoom;
  double _layersMinZoom;

  LMapOptions options;
  Map<String, Object> _targets;
  Map<String, StreamSubscription<Event>> _eventSubscribers;
  int _resizeRequest = 0;

  HtmlElement get mapPane => this._mapPane;
  bool get zoomAnimated => this._zoomAnimated;
  double get animationZoom => this._animateToZoom;
  double get layersMaxZoom => this._layersMaxZoom;
  double get layersMinZoom => this._layersMinZoom;
  set layersMaxZoom(double value) => _layersMaxZoom = value;
  set layersMinZoom(double value) => _layersMinZoom = value;
  HtmlElement get container => this._container;

  static LMapOptions createDefaultOptions() {
    return new LMapOptions();
  }

  LMap(Object id, [LMapOptions options])
  {
    this._loaded = false;
    this.options = h.setOrDefault(options, new LMapOptions());


    this._init(id);
  }

  _init(Object id) {
    this._zoomAnimated = this.options.zoomAnimation;
    this.initLayerBehavior(this);
    this.initControlBehavior(this);
    this._initContainer(id);
    this._initLayout();
    this.initDragBehavior(this);
  }

  _initContainer(Object id) {
    this._container = (id is String) ? document.querySelector(id) : id;
    if (this._container == null) {
      throw new Exception('Map container not found');
    }
    if (this._container.getAttribute('data-leaflet-id') != null) {
      throw new Exception('Map container is already initialized');
    }
    this._containerId = h.stamp(this._container);
    this._targets = <String, HtmlElement>{};
    this._targets[this._containerId] = this._container;
    this._eventSubscribers = <String,StreamSubscription<Event>>{};

    this._addSubscribers();
  }

  _removeSubscribers(){
    var keys = this._eventSubscribers.keys.toList();
    for(String key in keys){
      this._eventSubscribers[key].cancel();
      this._eventSubscribers.remove(key);
    }
  }

  _addSubscribers(){
    this._eventSubscribers['resize'] = window.onResize.listen(this._onResize);

  }

  _onResize(Event event){

    if (this._resizeRequest != 0){
      window.cancelAnimationFrame(this._resizeRequest);
    }
    this._resizeRequest = window.requestAnimationFrame((nun){
      this._invalidateSize({'debounceMoveend': true});
    });
  }

  _invalidateSize(Map<String,Object> options){
    if(!this._loaded){ return; }
    try{
      options =  h.extend({
        'animate': false,
        'pan': true
      }, options);

      var oldSize = this.getSize();
      this._sizeChanged = true;
      this._lastCenter = null;

      var newSize = this.getSize(),
          oldCenter = (oldSize / 2).round(),
          newCenter = (newSize /2 ).round(),
          offset = oldCenter - newCenter;
      if( offset.x == 0 && offset.y == 0) { return; }
      if (options['animate'] && options['pan']) {
        this.panBy(offset, null);
      } else {
        if (options['pan']) {
          this._rawPanBy(offset);
        }

        this.fire('move');

        if(options['debounceMoveend']) {
          if(this._sizeTimer != null){
            this._sizeTimer.cancel();
          }
          this._sizeTimer = new Timer(new Duration(milliseconds: 200), (){
            this.fire('moveend');
          });
        } else {
          this.fire('moveend');
        }
      }

      this.fire('resize', new EventData(this, {'oldSize': oldSize, 'newSize': newSize}));
    } catch(ex){
      h.dumpError(ex);
    }

  }

  bool get wantToFadeAnimation => this._fadeAnimated;

  _initLayout() {
    var container = this._container;
    this._fadeAnimated = this.options.fadeAnimation;
    h.addClass(container, 'leaflet-container');

    if (h.retina) {
      h.addClass(container, 'leaflet-retina');
    }

    if (this._fadeAnimated) {
      h.addClass(container, 'leaflet-fade-anim');
    }
    String position = container.style.position;
    if (position != 'absolute' &&
        position != 'relative' &&
        position != 'fixed') {
      container.style.position = 'relative';
    }
    this._initPanes();
    this.initControlPos();
  }

  _initPanes() {
    this._panes = <String, HtmlElement>{};
    this._mapPane = createPane('mapPane', this._container);
    setPosition(this._mapPane, new p.Point(0, 0));
    this.createPane('tilePane', this._mapPane);
    HtmlElement shadowPane = this.createPane('shadowPane', this._mapPane);
    this.createPane('overlayPane', this._mapPane);
    HtmlElement markerPane = this.createPane('markerPane', this._mapPane);
    this.createPane('overlayPane', this._mapPane);
    this.createPane('tooltipPane', this._mapPane);
    this.createPane('popupPane', this._mapPane);
    if (!this.options.markerZoomAnimation) {
      markerPane.classes.add('leaflet-zoom-hide');
      shadowPane.classes.add('leaflet-zoom-hide');
    }
  }

  HtmlElement createPane(String name, HtmlElement container) {
    HtmlElement pane = h.createPane(name, container);
    if (str.isNotEmpty(name)) {
      this._panes[name] = pane;
    }
    return pane;
  }

  setPosition(HtmlElement target, p.Point<num> position) {
    target.setAttribute(h.leaflet_pos, '${position.x},${position.y}');
    target.style.left = '${position.x}px';
    target.style.top = '${position.y}px';
  }

  p.Point getSize() {
    if (this._size == null || this._sizeChanged) {
      this._size = new p.Point(
          this._container.clientWidth, this._container.clientHeight);
      this._sizeChanged = false;
    }
    return this._size.clone();
  }

  HtmlElement getPane(String name) {
    return this._panes[name];
  }

  Map<String, HtmlElement> get panes => this._panes;
  double get zoom => this._zoom;

  addTarget(HtmlElement target, dynamic obj) {
    print('---addTarget----');
    print(target);
  }

  setView(List<double> center, double zoom, [Map<String, dynamic> options]) {
    try {
      bool moved;
      options = h.setOrDefault(options, <String,dynamic>{});
      bool reset = h.setOrDefault(options['reset'], false);
      zoom = (zoom > 0.0) ? this._limitZoom(zoom) : this._zoom;
      center = this._limitCenter(center, zoom, this.options.maxBounds);
      this._stop();

      if (this._loaded && reset == false) {
        if (options['animate'] != null) {
          options['zoom'] =
              h.extend({'animate': options['animate']}, options['zoom']);
          options['pan'] = h.extend(
              {'animate': options['animate'], 'duration': options['duration']},
              options['pan']);
        }

        if(this._zoom != zoom){
          moved = this._tryAnimatedZoom(center, zoom, options['zoom']);
        } else {
          moved = this._tryAnimatedPan(center, options['pan']);
        }

        if (moved) {
          if (this._sizeTimer != null) {
            this._sizeTimer.cancel();
            this._sizeTimer = null;
          }
          return;
        }
      }
      this._resetView(center, zoom);
    }catch (e){
      h.dumpError(e);
    }
  }

  setZoom(double zoom, [Map<String, dynamic> options]) {
    if (!this._loaded) {
      this._zoom = zoom;
      return;
    }
    this.setView(this.getCenter(), zoom, {'zoom': options});
  }

  _checkIfLoaded() {
    if (!this._loaded) {
      throw new Exception('Set map center and zoom first');
    }
  }

  List<double> getCenter() {
    this._checkIfLoaded();
    if (this._lastCenter != null && this._moved() == false) {
      return this._lastCenter;
    }
    LatLng latlng = this.layerPointToLatLng(this._getCenterLayerPoint());
    return [latlng.lat, latlng.lng];
  }

  p.Point _getCenterLayerPoint() {
    return this.containerPointToLayerPoint(this.getSize() / 2);
  }

  p.Point containerPointToLayerPoint(p.Point point) {
    return point - this._getMapPanePos();
  }

  p.Point layerPointToContainerPoint(p.Point p) => p + this._getMapPanePos();

  LatLng layerPointToLatLng(p.Point point) {
    var projectedPoint = point + this.getPixelOrigin();
    return this.unproject(projectedPoint);
  }

  LatLng containerPointToLatLng(p.Point p) {
    var layerPoint = this.containerPointToLayerPoint(p);
    return this.layerPointToLatLng(layerPoint);
  }

  getPixelOrigin() {
    this._checkIfLoaded();
    return this._pixelOrigin;
  }

  bool _moved() {
    p.Point pos = this._getMapPanePos();
    return pos.x.abs() + pos.y.abs() > 0.0;
  }

  bool _tryAnimatedPan(List<double> center, Map<String, dynamic> options) {
    p.Point offset = this._getCenterOffset(center).trunc();
    if (options != null &&
        options['animate'] != true &&
        !this.getSize().contains(offset)) {
      return false;
    }
    this.panBy(offset, options);
    return true;
  }

  fitBounds(LatLngBounds bounds, [Map<String, dynamic> options]) {
    if (!bounds.isValid) {
      throw new Exception('Bounds are not valid');
    }

    var target = this._getBoundsCenterZoom(bounds, options);
    this.setView(target.item1, target.item2, options);
  }

  Tuple2<List<double>, double> _getBoundsCenterZoom(
      LatLngBounds bounds, Map<String, dynamic> options) {
    options = options != null ? options : <String, dynamic>{};
    List<double> topLeft = h.parseNumList<double>(
        options['paddingTopLeft'], options['padding'], [0.0, 0.0]);
    List<double> bottomRight = h.parseNumList<double>(
        options['paddingBottomRight'], options['padding'], [0.0, 0.0]);

    p.Point paddingTL = new p.Point.fromList(topLeft);
    p.Point paddingBR = new p.Point.fromList(bottomRight);

    double zoom = this.getBoundsZoom(bounds, false, paddingTL + paddingBR);

    zoom =
        options['maxZoom'] is num ? math.min(options['maxZoom'], zoom) : zoom;

    if (zoom.isInfinite) {
      LatLng center = bounds.center;
      return new Tuple2([center.lat, center.lng], zoom);
    }

    p.Point paddingOffset = (paddingBR - paddingTL) * 0.5,
        swPoint = this.project(bounds.southWest, zoom),
        nePoint = this.project(bounds.northEast, zoom);
    LatLng center =
        this.unproject((swPoint + nePoint) * 0.5 + paddingOffset, zoom);

    return new Tuple2([center.lat, center.lng], zoom);
  }

  double getBoundsZoom(LatLngBounds bounds, bool inside, p.Point padding) {
    double zoom = h.setOrDefault(this.zoom, 0.0), min = this.minZoom, max = this.maxZoom;
    LatLng nw = bounds.northWest, se = bounds.southEast;
    p.Point size = this.getSize() - padding;


    Bounds gBounds =
        new Bounds.fromPoints([this.project(se, zoom), this.project(nw, zoom)]);
    p.Point boundsSize = gBounds.size;
    double snap = this.options.zoomSnap != null ? this.options.zoomSnap : 1;
    double scaleX = size.x / boundsSize.x;
    double scaleY = size.y / boundsSize.y;
    double scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    zoom = this.getScaleZoom(scale, zoom);
    if (snap > 0) {
      zoom = (zoom * 100 / snap).round() * snap / 100;
      zoom =
          inside ? (zoom / snap).ceil() * snap : (zoom / snap).floor() * snap;
    }

    return math.max(min, math.min(max, zoom));
  }

  double getScaleZoom(double scale, double zoom) {
    CRS crs = this.options.crs;
    zoom = h.setOrDefault(zoom, this._zoom);
    return crs.zoom(scale * crs.scale(zoom));
  }

  fitWorlds(Map<String, dynamic> options) {
    this.fitBounds(
        new LatLngBounds.fromCorners(
            new LatLng(-90.0, -180.0), new LatLng(90.0, 180.0)),
        options);
  }

  panTo(List<double> center, Map<String, dynamic> options) {
    this.setView(center, this._zoom, options);
  }

  panBy(p.Point offset, Map<String, dynamic> options) {
    offset = offset.round();
    options = h.setOrDefault(options, <String, dynamic>{});

    if (offset.x == 0 && offset.y == 0) {
      return this.fire('moveend');
    }

    if (options['animate'] != true && !this.getSize().contains(offset)) {
      List<double> centerXY = this.getCenter();
      LatLng centerLatLng =
          this.unproject(this.project(h.toLatLng(centerXY)) + offset);
      this._resetView(
          [centerLatLng.lat, centerLatLng.lng], this.zoom);
    }

    if (this._panAnim == null) {
      this._panAnim = new PosAnimation();
      this._panAnim.on({
        'step': this._onPanTransitionStep,
        'end': this._onPanTransitionEnd,
      });
    }

    if (options['noMoveStart'] == false) {
      this.fire('movestart');
    }

    if (options['animate'] != false) {
      this._mapPane.classes.add('leaflet-pan-anim');
      p.Point newPos = this._getMapPanePos() - offset;
      newPos = newPos.round();
      this._panAnim.run(
          this._mapPane,
          newPos,
          h.setOrDefault<double>(options['duration'], 0.25),
          h.setOrDefault<double>(options['easeLinearity'], 0.5));
    } else {
      this._rawPanBy(offset);
      this.fire('move');
      this.fire('moveend');
    }
  }

  _rawPanBy(p.Point offset) {
    h.setPosition(this._mapPane, this._getMapPanePos() - offset);
  }

  void _onPanTransitionStep([dynamic context, AppEvent event]) {
    this.fire('move');
  }

  double getZoomSpan(){
    return this._getMaxZoom() - this._getMinZoom();
  }

  double _getMaxZoom(){
    return h.setOrDefault(this.options.maxZoom, h.setOrDefault(this._layersMaxZoom, double.infinity));
  }

  double _getMinZoom(){
    return  h.setOrDefault(this.options.minZoom, h.setOrDefault(this._layersMinZoom, 0.0));
  }

  void _onPanTransitionEnd([dynamic context, AppEvent event]) {
    this._mapPane.classes.remove('leaflet-pan-anim');
    this.fire('moveend');
  }

  bool _tryAnimatedZoom (List<double> center, double zoom, Map<String, dynamic> options) {
    if (this._animatingZoom) {
      return true;
    }
    options = h.setOrDefault(options, <String,dynamic>{});
    if (!this._zoomAnimated ||
        options['animate'] == false ||
        this._nothingToAnimate() ||
        (zoom - this._zoom).abs() > this.options.zoomAnimationThreshold) {
      return false;
    }
    double scale = this.getZoomScale(zoom);
    p.Point offset = this._getCenterOffset(center) / (1 - 1 / scale);

    if (options['animate'] != true && !this.getSize().contains(offset)) {
      return false;
    }

    onAnimate(num highResTime) {
      this._moveStart(true, true);
      this._animateZoom(center, zoom, true);
    }

    window.requestAnimationFrame(onAnimate);
    return true;
  }

  _animateZoom(List<double> center, double zoom, bool startAnim,
      [bool noUpdate]) {
    if (this._mapPane == null) {
      return;
    }
    if (startAnim) {
      this._animatingZoom = true;
      this._animateToCenter = center;
      this._animateToZoom = zoom;
      h.addClass(this._mapPane, 'leaflet-zoom-anim');
    }
    EventData data = new EventData(
        this, {'center': center, 'zoom': zoom, 'noUpdate': noUpdate});

    this.fire('zoomanim', data);

    new Timer(new Duration(milliseconds: 250), this._onZoomTransitionEnd);
  }

  _onZoomTransitionEnd(){
    if(!this._animatingZoom) {return;}
    if(this._mapPane != null){
      h.removeClass(this._mapPane, 'leaflet-zoom-anim');
    }
    this._animatingZoom = false;
    this._move(this._animateToCenter, this._animateToZoom);
  }

  double getZoomScale(double toZoom, [double fromZoom]) {
    var crs = this.options.crs;
    fromZoom = fromZoom != null ? fromZoom : this._zoom;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  p.Point _getCenterOffset(List<double> center) {
    LatLng latlng = h.toLatLng(center);
    return this.latLngToLayerPoint(latlng) - this._getCenterLayerPoint();
  }

  p.Point latLngToLayerPoint(LatLng latlng) {
    var projectedPoint = this.project(latlng).round();
    return projectedPoint - this.getPixelOrigin();
  }

  p.Point latLngToContainerPoint(LatLng latlng) {
    var layerP = this.latLngToLayerPoint(latlng);
    return this.layerPointToContainerPoint(layerP);
  }

  p.Point latLngToNewLayerPoint(LatLng latlng, num zoom, List<double> center){
    var topLeft = this.getNewPixelOrigin(center, zoom);
    return this.project(latlng, zoom) - topLeft;
  }

  Bounds getPixelWorldBounds(num zoom) =>
    this.options.crs.getProjectedBounds(h.setOrDefault(zoom, this.zoom));

  LatLng layerPointToLagLng(p.Point point) {
    var projectedPoint = point + this.getPixelOrigin();
    return this.unproject(projectedPoint);
  }



  LatLng wrapLatLng(LatLng latlng) {
    return this.options.crs.wrapLatLng(latlng);
  }

  LatLngBounds wrapLatLngBounds(LatLngBounds bounds) {
    return this.options.crs.wrapLatLngBounds(bounds);
  }

  _nothingToAnimate() {
    return this._container.querySelectorAll('.leaflet-zoom-animated').isEmpty;
  }

  stop() {
    this.setZoom(this._limitZoom(this._zoom));
    if (this.options.zoomSnap != 0) {
      this.fire('viewreset');
    }
    this._stop();
  }

  _stop() {
    h.cancelAnimFrame(h.setOrDefault<num>(this._flyToFrame,0));
    if (this._panAnim != null) {
      this._panAnim.stop();
    }
  }

  p.Point limitOffset(p.Point offset, [LatLngBounds bounds]) {
    if(bounds == null){
      return offset;
    }
    var viewBounds = this.getPixelBounds(null, null),
      newBounds = new Bounds.fromPoints([viewBounds.min + offset, viewBounds.max + offset]);

    return offset + (this._getBoundsOffset(newBounds, bounds, this.zoom));
  }

  List<double> _limitCenter(List<double> center, double zoom,
      [LatLngBounds bounds]) {
    if (bounds == null) {
      return center;
    }

    p.Point centerPoint = this.project(h.toLatLng(center), zoom);
    p.Point viewHalf = this.getSize() * 0.5;
    Bounds viewBounds =
        new Bounds.fromPoints([centerPoint - viewHalf, centerPoint + viewHalf]);
    p.Point offset = this._getBoundsOffset(viewBounds, bounds, zoom);
    p.Point roundedOffset = offset.round();
    if (roundedOffset.x == 0 && roundedOffset.y == 0) {
      return center;
    }
    LatLng latlng = this.unproject(centerPoint + offset, zoom);
    return [latlng.lat, latlng.lng];
  }

  p.Point _getBoundsOffset(
      Bounds pxBounds, LatLngBounds maxBounds, double zoom) {
    Bounds projectedMaxBounds = new Bounds.fromPoints([
      this.project(maxBounds.northEast, zoom),
      this.project(maxBounds.southWest, zoom)
    ]);
    p.Point minOffset = projectedMaxBounds.min - pxBounds.min;
    p.Point maxOffset = projectedMaxBounds.max - pxBounds.max;
    double dx = this._rebound(minOffset.x, -maxOffset.x);
    double dy = this._rebound(minOffset.y, -maxOffset.y);

    return new p.Point(dx, dy);
  }

  double _rebound(double left, double right) {
    return (left + right) > 0.0
        ? (left - right).round() / 2
        : math.max(0.0, left.ceilToDouble()) -
            math.max(0.0, right.floorToDouble());
  }

  _resetView(List<double> center, double zoom) {
    this.setPosition(this._mapPane, new p.Point(0, 0));
    bool loading = !this._loaded;
    this._loaded = true;
    zoom = this._limitZoom(zoom);
    this.fire('viewprereset');

    bool zoomChanged = zoom != this._zoom;
    this._moveStart(zoomChanged, true)
        ._move(center, zoom)
        ._moveEnd(zoomChanged);

    this.fire('viewreset');

    if (loading) {
      this.fire('load');
    }
  }

  whenReady(EventFunc callback, dynamic context) {
    if (this._loaded) {
      this.runEventFunc('mapready', callback, context);
    } else {
      this.on('load',callback, context);
    }
  }

  p.Point _getTopLeftPoint(p.Point center, num zoom){
    var pixelOrigin = center != null && zoom != null
        ? this.getNewPixelOrigin([center.x, center.y], zoom)
        : this.getPixelOrigin();

    return pixelOrigin - this._getMapPanePos();
  }


  Bounds getPixelBounds(p.Point center, num zoom){
    var tlPoint = this._getTopLeftPoint(center, zoom);
    return new Bounds.fromPoints([tlPoint, tlPoint + this.getSize()]);
  }

  LMap _moveStart(bool zoomChanged, bool triggerMoveStart) {
    if (zoomChanged) {
      this.fire('zoomstart');
    }
    if (triggerMoveStart) {
      this.fire('movestart');
    }
    return this;
  }

  LMap _move(List<double> center, double zoom, [EventData data]) {
    if (zoom == null) {
      zoom = this._zoom;
    }
    bool zoomChanged = zoom != this._zoom;

    this._zoom = zoom;
    this._lastCenter = center;
    this._pixelOrigin = this.getNewPixelOrigin(center);
    if (zoomChanged || (data != null && data.pinch)) {
      this.fire('zoom', data);
    }
    this.fire('move', data);
    return this;
  }

  _moveEnd(bool zoomChanged) {
    if (zoomChanged) {
      this.fire('zoomend');
    }
    this.fire('moveend');
  }

  double _limitZoom(double zoom) {
    double min = minZoom, max = maxZoom, snap = this.options.zoomSnap;
    if (snap != 0) {
      zoom = (zoom / snap).round() * snap;
    }
    return math.max(min, math.min(max, zoom));
  }

  double get minZoom => this.options.minZoom;
  double get maxZoom => this.options.maxZoom;

  p.Point getNewPixelOrigin(List<double> center, [double zoom]) {
    p.Point viewHalf = this.getSize() / 2;
    return this.project(h.toLatLng(center), zoom) -
        viewHalf +
        this._getMapPanePos();
  }

  p.Point<num> _getMapPanePos() => h.getPosition(this._mapPane);

  p.Point project(LatLng latlng, [double zoom]) {
    zoom = zoom != null ? zoom : this._zoom;
    return this.options.crs.latLngToPoint(latlng, zoom);
  }

  LatLng unproject(p.Point point, [double zoom = 0.0]) {
    zoom = zoom != 0.0 ? zoom : this._zoom;
    return this.options.crs.pointToLatLng(point, zoom);
  }

  bool get loaded => this._loaded;

  addInteractiveTarget(HtmlElement el){
    this._targets[h.stamp(el)] = el;
  }

  removeInteractiveTarget(HtmlElement el){
    this._targets.remove(h.stamp(el));
  }
}
