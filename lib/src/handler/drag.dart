import 'dart:math' as math;

import 'handler.dart';
import 'package:leaflet/src/base/draggable.dart';
import 'package:leaflet/src/lmap.dart';
import 'package:leaflet/src/lmap_options.dart';
import 'package:leaflet/src/base/evented.dart';
import 'package:leaflet/src/utility/helper.dart' as h;
import 'package:leaflet/src/base/point.dart' as p;
import 'package:leaflet/src/base/bounds.dart';

class Drag extends Handler {
  Draggable _draggable;
  List<p.Point> _positions;
  List<DateTime> _times;
  Bounds _offsetLimit;
  num _viscosity;
  DateTime _lastTime;
  p.Point _lastPos;
  num _initialWorldOffset;
  num _worldWidth;

  Drag(LMap map) : super(map);

  @override
  addHooks() {
    if (this._draggable == null) {
      var map = this.map;
      this._draggable =
          new Draggable(map.mapPane, dragStartTarget: map.container);
      this._draggable.on({
        'dragstart': this._onDragStart,
        'drag': this._onDrag,
        'dragend': this._onDragEnd,
        'predrag': this._onPreDragLimit,
      }, null, this);

      if (map.options.worldCopyJump) {
        this._draggable.on('predrag', this._onPreDragWrap, this);
        map.on('zoomend', this._onZoomEnd, this);
        map.whenReady(this._onZoomEnd, this);
      }
    }
    h.addClass(map.container, 'leaflet-grab leaflet-touch-drag');
    this._draggable.enable();
    this._positions = <p.Point>[];
    this._times = <DateTime>[];
  }

  @override
  removeHooks() {
    h.removeClass(this.map.container, 'leaflet-grab');
    h.removeClass(this.map.container, 'leaflet-touch-drag');
  }

  bool get _moved => this._draggable != null && this._draggable.moved;

  bool get _moving => this._draggable != null && this._draggable.moving;

  void _onDragStart([dynamic context, AppEvent appEvent]) {
    try {
      var map = this.map;
      map.stop();

      if (map.options.maxBounds != null &&
          map.options.maxBoundsViscosity != null) {
        var bounds = h.boundsToLatLngBounds(map.options.maxBounds);
        this._offsetLimit = new Bounds.fromPoints([
          map.latLngToContainerPoint(bounds.northWest) * (-1),
          map.latLngToContainerPoint(bounds.southEast) * (-1) + map.getSize()
        ]);
        this._viscosity =
            math.min(1.0, math.max(0.0, map.options.maxBoundsViscosity));
      } else {
        this._offsetLimit = null;
      }
      map.fire('movestart');
      map.fire('dragstart');

      if (map.options.inertia) {
        this._positions = [];
        this._times = [];
      }
    } catch (ex) {
      h.dumpError(ex);
    }
  }

  void _onDrag([dynamic context, AppEvent appEvent]) {
    try {
      var map = this.map;
      if (map.options.inertia) {
        this._lastTime = new DateTime.now();
        this._lastPos =
            h.setOrDefault(this._draggable.newPos, new p.Point(0, 0));
        this._positions.add(this._lastPos);
        this._times.add(this._lastTime);
        this._prunePositions(this._lastTime);
      }
      map.fire('move', appEvent.eventData);
      map.fire('drag', appEvent.eventData);
    } catch (ex) {
      h.dumpError(ex);
    }
  }

  void _prunePositions(DateTime time) {
    bool run = this._needPrunePositions(time);
    while (run) {
      this._positions.removeAt(0);
      this._times.removeAt(0);
      run = this._needPrunePositions(time);
    }
  }

  bool _needPrunePositions(DateTime time) =>
      this._positions.length > 1 &&
      this._times.isNotEmpty &&
      time.difference(this._times[0]).inMilliseconds > 50;


  void _onZoomEnd([dynamic context, AppEvent appEvent]) {
      var map = this.map;
    var pxCenter = map.getSize() * 0.5,
        pxWorldCenter = map.latLngToLayerPoint(h.toLatLng([0.0, 0.0]));
    this._initialWorldOffset = (pxWorldCenter - pxCenter).x;
    this._worldWidth = map.getPixelWorldBounds(map.zoom).size.x;
  }

  num _viscousLimit(num value, num threshold) =>
      value - (value - threshold) * this._viscosity;

  void _onPreDragLimit([dynamic context, AppEvent appEvent]) {
    if (this._viscosity == null || this._offsetLimit == null) {
      return;
    }

    var offset = this._draggable.newPos - this._draggable.startPos;
    var limit = this._offsetLimit;
    var x = offset.x, y = offset.y;

    if (x < limit.min.x) {
      x = this._viscousLimit(x, limit.min.x);
    }
    if (y < limit.min.y) {
      y = this._viscousLimit(y, limit.min.y);
    }
    if (x > limit.max.x) {
      x = this._viscousLimit(x, limit.max.x);
    }
    if (y > limit.max.y) {
      y = this._viscousLimit(y, limit.max.y);
    }
    offset = new p.Point(x, y);
    this._draggable.newPos = this._draggable.startPos + offset;

  }

  void _onPreDragWrap([dynamic context, AppEvent appEvent]) {
    var worldWidth = this._worldWidth,
        halfWidth = (worldWidth / 2).round(),
        dx = this._initialWorldOffset,
        x = this._draggable.newPos.x,
        newX1 = (x - halfWidth + dx) % worldWidth + halfWidth - dx,
        newX2 = (x + halfWidth + dx) % worldWidth - halfWidth - dx,
        newX = (newX1 + dx).abs() < (newX2 + dx).abs() ? newX1 : newX2;

    this._draggable.absPos = this._draggable.newPos.clone();
    this._draggable.newPos = new p.Point(newX, this._draggable.newPos.y);
  }

  void _onDragEnd([dynamic context, AppEvent appEvent]) {
    try {
      var map = this.map,
          options = map.options,
          noInertia = !options.inertia || this._times.length < 2;
      var eventData =
          appEvent != null ? appEvent.eventData : new EventData(context);

      map.fire('dragend', eventData);
      if (noInertia) {
        map.fire('moveend', eventData);
        return;
      }
      this._prunePositions(new DateTime.now());
      var obj = this._calculateProperties(options);
      if (obj == null) {
        map.fire('moveend', eventData);
        return;
      }

      var offset = obj['offset'],
          decelerationDuration = obj['decelerationDuration'],
          ease = obj['ease'];

      offset = map.limitOffset(offset, map.options.maxBounds);
      h.requestAnimFrame((num resolution) {
        map.panBy(offset, {
          'duration': decelerationDuration,
          'easeLinearity': ease,
          'noMoveStart': true,
          'animate': true
        });
      });
    } catch (ex) {
      h.dumpError(ex);
    }
  }

  Map<String, dynamic> _calculateProperties(LMapOptions options) {
    var direction,
        duration,
        ease,
        speedVector,
        limitedSpeed,
        limitedSpeedVector,
        decelerationDuration,
        offset;

    direction = this._lastPos - this._positions[0];
    duration = this._lastTime.difference(this._times[0]).inMilliseconds / 1000;
    ease = options.easeLinearity;
    speedVector = direction * (ease / duration);
    num speed = speedVector.distanceTo(new p.Point(0, 0));
    if (speed.isNaN) {
      return null;
    }

    limitedSpeed = math.min(options.inertiaMaxSpeed, speed);
    limitedSpeedVector = speedVector * (limitedSpeed / speed);
    decelerationDuration = limitedSpeed / (ease * options.inertiaDeceleration);
    p.Point newPoint = (limitedSpeedVector * (-decelerationDuration / 2));

    if (newPoint.x.isNaN) {
      return null;
    }

    offset = newPoint.round();
    return <String, dynamic>{
      'offset': offset,
      'ease': ease,
      'decelerationDuration': decelerationDuration
    };
  }
}
