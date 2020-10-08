import 'dart:html';
import 'dart:async';

import 'package:leaflet_map/src/utility/helper.dart' as h;
import 'package:leaflet_map/src/base/evented.dart';
import 'package:leaflet_map/src/base/point.dart' as p;

class Draggable extends Evented {
  static Draggable _draggable;

  bool _enabled = false;
  HtmlElement _element;
  num _clickTolerance = 3;
  HtmlElement _dragStartTarget;
  HtmlElement _lastTarget;
  bool _preventOutline;
  bool _moved = false;
  bool _moving = false;
  p.Point newPos;
  p.Point startPos;
  p.Point _startPoint;
  p.Point absPos;
  Map<String, StreamSubscription> _eventRegistries;
  num _animRequest;
  Event _lastEvent;

  static const _EVENT_TOUCH_START = 'touchstart';
  static const _EVENT_MOUSE_DOWN = 'mousedown';
  static const _EVENT_TOUCH_END = 'touchend';
  static const _EVENT_MOUSE_UP = 'mouseup';
  static const _EVENT_MOUSE_MOVE = 'mousemove';
  static const _EVENT_TOUCH_MOVE = 'touchmove';

  bool get moved => this._moved;
  bool get moving => this._moving;

  Draggable(this._element,
      {HtmlElement dragStartTarget,
      bool preventOutline = false,
      int clickTolerance = 3}) {
    this._dragStartTarget = h.setOrDefault(dragStartTarget, this._element);
    this._clickTolerance = clickTolerance;
    this._preventOutline = preventOutline;
    this._eventRegistries = <String, StreamSubscription>{};
  }

  void enable() {
    if (!this._enabled) {
      this._addListener(
          this._dragStartTarget, _EVENT_MOUSE_DOWN, this._onDown, this);
      this._addListener(
          this._dragStartTarget, _EVENT_TOUCH_START, this._onDown, this);
      this._enabled = true;
    }
  }

  void disable() {
    if (!this._enabled) {
      return;
    }
    this._finishDrag();
    this._removeListener(
        this._dragStartTarget, _EVENT_TOUCH_START, this._onDown, this);
    this._removeListener(
        this._dragStartTarget, _EVENT_MOUSE_DOWN, this._onDown, this);
    this._enabled = false;
    this._moved = false;
  }

  void _onDown([dynamic context, AppEvent appEvent]) {
    try {
      if (!this._enabled) {
        return;
      }

      this._moved = false;
      if (this._element.classes.contains('leaflet-zoom-anim')) {
        return;
      }

      if (Draggable._draggable != null) {
        return;
      }

      Draggable._draggable = this;

      if (this._preventOutline) {
        h.preventOutline(this._element);
      }

      h.disableImageDrag();
      h.disableTextSelection();

      if (this._moving) {
        return;
      }

      this.fire('down');

      Map<String, dynamic> data = appEvent.eventData.data;
      MouseEvent evt = data['event'] as MouseEvent;
      this._startPoint = new p.Point(evt.client.x, evt.client.y);

      this._addListener(
          document.documentElement, _EVENT_MOUSE_MOVE, this._onMove, this);
      this._addListener(
          document.documentElement, _EVENT_MOUSE_UP, this._onUp, this);
    } catch (ex) {
      h.dumpError(ex);
    }
  }

  void _onMove([dynamic context, AppEvent appEvent]) {
    try {
      if (!this._enabled) {
        return;
      }

      var evt = appEvent.eventData.data['event'] as MouseEvent,
          newPoint = new p.Point(evt.client.x, evt.client.y),
          offset = newPoint - this._startPoint;

      if (offset.x == 0 && offset.y == 0) {
        return;
      }


      if (offset.x.abs() + offset.y.abs() < this._clickTolerance) {
        return;
      }

      h.preventDefault(evt);

      if (!this._moved) {
        this.fire('dragstart');
        this._moved = true;
        this.startPos = h.getPosition(this._element) - offset;
        h.addClass(document.body, 'leaflet-dragging');
        this._lastTarget = evt.target;
        h.addClass(this._lastTarget, 'leaflet-drag-target');
      }

      this.newPos = this.startPos + offset;
      this._moving = true;

      h.cancelAnimFrame(this._animRequest);
      this._lastEvent = evt;
      this._animRequest = h.requestAnimFrame(this._updatePosition);
    } catch (ex) {
      h.dumpError(ex);
    }
  }

  void _updatePosition(num resolution) {
    var eventData = new EventData(this, {'originalEvent': this._lastEvent});
    this.fire('predrag', eventData);
    h.setPosition(this._element, this.newPos);
    this.fire('drag', eventData);
  }

  void _onUp([dynamic context, AppEvent appEvent]) {
    if (!this._enabled) {
      return;
    }
    this._finishDrag();
  }

  void _finishDrag() {
    h.removeClass(document.body, 'leaflet-dragging');
    if (this._lastTarget != null) {
      h.removeClass(this._lastTarget, 'leaflet-drag-target');
      this._lastTarget = null;
    }

    this._removeListener(
        document.documentElement, _EVENT_MOUSE_MOVE, this._onMove, this);
    this._removeListener(
        document.documentElement, _EVENT_MOUSE_UP, this._onUp, this);

    h.enableImageDrag();
    h.enableTextSelection();
    if (this._moved && this._moving) {
      h.cancelAnimFrame(this._animRequest);
      this.fire(
          'dragend',
          new EventData(
              this, {'distance': this.newPos.distanceTo(this.startPos)}));
    }
    this._moving = false;
    Draggable._draggable = null;
  }

  void _addListener(
      HtmlElement el, String eventType, EventFunc fn, dynamic context) {
    String id = h.stamp(el);
    String registryKey = this._genRegistryKey(id, eventType);
    if (this._listenerAdded(registryKey)) {
      return;
    }

    var handler = (Event evt) {
      var data = <String, dynamic>{};
      data['event'] = evt;
      if (evt is MouseEvent) {
        data['shiftKey'] = evt.shiftKey;
        data['button'] = evt.button;
      }
      if (evt is KeyboardEvent) {
        data['shiftKey'] = evt.shiftKey;
        data['button'] = evt.which;
      }

      AppEvent appEvent =
          new AppEvent(type: eventType, eventData: new EventData(this, data));

      fn(this, appEvent);
    };

    switch (eventType) {
      case _EVENT_MOUSE_DOWN:
        this._eventRegistries[registryKey] = el.onMouseDown.listen(handler);
        break;
      case _EVENT_TOUCH_START:
        this._eventRegistries[registryKey] = el.onTouchStart.listen(handler);
        break;
      case _EVENT_MOUSE_MOVE:
        this._eventRegistries[registryKey] = el.onMouseMove.listen(handler);
        break;
      case _EVENT_TOUCH_MOVE:
        this._eventRegistries[registryKey] = el.onTouchMove.listen(handler);
        break;
      case _EVENT_MOUSE_UP:
        this._eventRegistries[registryKey] = el.onMouseUp.listen(handler);
        break;
      case _EVENT_TOUCH_END:
        this._eventRegistries[registryKey] = el.onTouchEnd.listen(handler);
        break;
    }
  }

  void _removeListener(
      HtmlElement el, String eventType, EventFunc fn, dynamic context) {
    var id = h.stamp(el);
    var registryKey = this._genRegistryKey(id, eventType);
    if (this._eventRegistries.containsKey(registryKey)) {
      this._eventRegistries[registryKey].cancel();
      this._eventRegistries.remove(registryKey);
    }
  }

  String _genRegistryKey(String id, String eventType) {
    return 'evt_${eventType}_$id';
  }

  bool _listenerAdded(String eventKey) {
    return _eventRegistries.containsKey(eventKey);
  }
}
