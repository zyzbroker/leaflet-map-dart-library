import 'dart:html';
import 'dart:math' as math;
import 'dart:async';

import 'package:quiver/strings.dart' as q;
import 'package:tuple/tuple.dart';
import 'package:leaflet/src/base/latlng_bounds.dart';

import 'dom.dart';
import 'package:leaflet/src/base/latlng.dart';
import 'package:leaflet/src/base/point.dart' as p;

typedef FuncDefinition([dynamic arguments]);

double wrapNum(num x, Tuple2<num, num> range, [bool includeMax = false]) {
  double max = range.item2;
  double min = range.item1;
  double diff = max - min;

  return x == max && includeMax == true ? x: ((x - min) % diff + diff) % diff + min;
}

num formatNum(num value, [num digits = 6]){
  digits = digits == null ? 6 : digits;
  var pow = math.pow(10, digits);
  return (value * pow).round() / pow;
}

bool testProp(List<String> props){
  var style = document.documentElement.styleMap.getProperties();
  for(String prop in props){
    if(style.contains(prop)){
      return true;
    }
  }
  return false;
}

HtmlElement createPane(String name, HtmlElement container){
  String className = 'leaflet-pane' +
      (q.isNotEmpty(name) ? ' leaflet-' + name.replaceAll('Pane','') + '-pane' : '');
  return createElement(tagName: 'div', className: className, container: container);
}

bool get retina => window.devicePixelRatio != null && window.devicePixelRatio > 1;


RegExp _templateRe = new RegExp(r"\{ *([\w_-]+) *\}");
String template(String str, Map<String, String> data) {
  return str.replaceAllMapped(_templateRe, (Match match) {
    var value = data[match.group(1)];
    if (value == null) {
      throw ("No value provided for variable ${match.group(1)}");
    } else {
      return value;
    }
  });
}

class _IdGenerator{
  int _id;

  static final _IdGenerator _idGenerator = new _IdGenerator._internal();
  _IdGenerator._internal():
        this._id = 0;

  factory _IdGenerator(){
    return _idGenerator;
  }

  int get nextId => ++_id;
}

String _leaflet_id = 'data-leaflet-id';
String stamp(HtmlElement obj){
  String id = obj.getAttribute(_leaflet_id);
  if(q.isNotEmpty(id)){
    return id;
  }
  _IdGenerator ig = new _IdGenerator();
  id = ig.nextId.toString();
  obj.setAttribute(_leaflet_id, id);
  return id;
}

String getNextId(){
  _IdGenerator idG = new _IdGenerator();
  return idG.nextId.toString();
}

String emptyImageUrl = 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=';


String leaflet_pos = 'data-leaflet-pos';

p.Point<num> getPosition(HtmlElement el){
  String point = el.getAttribute(leaflet_pos);
  if (q.isEmpty(point)){
    return new p.Point(0.0, 0.0);
  }

  try{
      return new p.Point.fromString(point);
  }catch(e){
    print(e);
    return new p.Point(0.0, 0.0);
  }
}

setTransform(HtmlElement el, p.Point<num> offset, [double scale=0.0]){
  p.Point<num> pos = offset == null ? new p.Point<num>(0.0, 0.0) : offset;
  double x = pos.x, y = pos.y;
  String scl = (scale > 0.0) ? 'scale(${scale})' : '';
  el.style.transform ='translate3d(${x}px,${y}px,0px) $scl';
}

setPosition(HtmlElement el, p.Point<num> point){
  el.setAttribute(leaflet_pos, point.toString());
  setTransform(el, point);
}

Map<String, dynamic> extend(Map<String, dynamic> dest, dynamic source){
  if(source == null){
    return dest;
  }
  Map<String, dynamic> src = source as Map<String, dynamic>;
  for(String key in src.keys){
    dest[key] = src[key];
  }
  return dest;
}

num requestAnimFrame(FrameRequestCallback callback){
  return window.requestAnimationFrame(callback);
}

cancelAnimFrame(num id){
  if(id != null && id > 0){
    window.cancelAnimationFrame(id);
  }
}

num trunc(num v){
  return v > 0 ? v.floor() : v.ceil();
}

List<T> parseNumList<T extends num>(dynamic value, dynamic orValue, List<T> defaultValue){
  if(value != null && value is List<T>){
    return value;
  }
  if(orValue != null && orValue is List<T>){
    return orValue;
  }

  return defaultValue;
}

T setOrDefault<T extends Object>(T value, T defaultValue){
  return value !=  null ? value : defaultValue;
}


LatLng toLatLng(List<double> xy){
  return new LatLng(xy[0], xy[1]);
}

p.Point<num> latLngToPoint(LatLng latlng){
  return new p.Point<num>.fromLatLng(latlng);
}

List<double> latLngToList(LatLng latlng){
  return [latlng.lat, latlng.lng];
}

toFront(HtmlElement el){
  var parent = el.parent;
  if (parent.lastChild != el){
    parent.append(el);
  }
}

toBack(HtmlElement el){
 var parent = el.parent;
 if(parent.firstChild != el) {
   parent.insertBefore(el, parent.firstChild);
 }
}

setOpacity(HtmlElement el, num value){
  el.style.opacity = value.toString();
}

LatLngBounds boundsToLatLngBounds<T extends Object>(T a, [T b]){
  if(a is LatLngBounds){
    return a;
  } else if (a is double && b is double){
    return new LatLngBounds(toLatLng([a, b]));
  }

  return new LatLngBounds(toLatLng([
    double.parse(a.toString()),
    double.parse(b.toString())]));
}

LatLngBounds toLatLngBounds(List<num> xy1, List<num> xy2){
  return new LatLngBounds.fromCorners(toLatLng(xy1), toLatLng(xy2));
}

bool android = window.navigator.userAgent.contains('android');
bool android23 = window.navigator.userAgent.contains('android 2') ||
  window.navigator.userAgent.contains('android 3');

T parseT<T>(dynamic t) => (t is T) ? t : null;

dumpError(Object ex){
  if(ex is Error){
    print(ex.toString());
    print(ex.stackTrace);
  } else if (ex is Exception){
    print(ex.toString());
  }

}

addClass(HtmlElement el, String name){
  List<String> classes = name.split(' ');
  if(el.classes.isEmpty){
    el.classes.addAll(classes);
  } else {
    var newClasses = <String>[];
    for(String c in classes){
      if(!el.classes.contains(c)){
        newClasses.add(c);
      }
    }
    if(newClasses.isNotEmpty){
      el.classes.addAll(newClasses);
    }
  }
}

removeClass(HtmlElement el, String name){
  List<String> classes = name.split(' ');
  el.classes.removeWhere((c)=> classes.contains(c));
}

disableScrollPropagation(HtmlElement el){
  el.onMouseWheel.listen(stopPropagation);
}

disableClickPropagation(HtmlElement el){
  el.onMouseDown.listen(stopPropagation);
  el.onTouchStart.listen(stopPropagation);
  el.onDoubleClick.listen(stopPropagation);
  el.onClick.listen(stopPropagation);
}

stopPropagation(dynamic e){
  if( e is Event) {
    e.stopPropagation();
  }
}

stop(Event evt) {
  evt.preventDefault();
  evt.stopPropagation();
}

preventDefault(Event evt){
  evt.preventDefault();
}

LatLngBounds getLatLngBounds(List<LatLng> points){
  num maxX = points[0].lat, minX =points[0].lat, minY = points[0].lng, maxY = points[0].lng;
  for(LatLng p in points) {
    if (maxX < p.lat) {
      maxX = p.lat;
    } else if (minX > p.lat) {
      minX = p.lat;
    }

    if (maxY < p.lng) {
      maxY = p.lng;
    } else if (minY > p.lng) {
      minY = p.lng;
    }
  }
  return new LatLngBounds.fromCorners(toLatLng([maxX, minY]), toLatLng([minX, maxY]));
}

HtmlElement _outlineElement;
String _outlineStyle;
StreamSubscription _outlineSubscriber;
StreamSubscription _imageDragSubscriber;

void disableImageDrag(){
  _imageDragSubscriber = window.onDragStart.listen(preventDefault);
}

void enableImageDrag(){
  if(_imageDragSubscriber !=  null){
    _imageDragSubscriber.cancel();
    _imageDragSubscriber = null;
  }
}

StreamSubscription _textSelectionSubscriber;

void disableTextSelection(){
  _textSelectionSubscriber = document.onSelectStart.listen(preventDefault);
}

void enableTextSelection(){
  if(_textSelectionSubscriber != null){
    _textSelectionSubscriber.cancel();
    _textSelectionSubscriber = null;
  }
}

void restoreOutline(Event evt){
  if(_outlineElement == null) {
    return;
  }
  _outlineElement.style.outline = _outlineStyle;
  _outlineElement = null;
  _outlineStyle = null;
  _outlineSubscriber.cancel();
  _outlineSubscriber = null;
}

void preventOutline(HtmlElement el){
  while(el.tabIndex == -1){
    el = el.parent;
  }

  if(el.style.outline == null){ return; }
  _outlineStyle = el.style.outline;
  _outlineElement = el;
  el.style.outline = 'none';
  _outlineSubscriber = window.onKeyDown.listen(restoreOutline);
}