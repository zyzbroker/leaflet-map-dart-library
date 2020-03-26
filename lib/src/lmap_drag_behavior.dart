import 'package:leaflet/src/handler/drag.dart';
import 'package:leaflet/src/lmap.dart';

abstract class LMapDragBehavior {
  Drag _drag;

  void initDragBehavior(LMap map){
    this._drag = new Drag(map);
    this._drag.enable();
  }
}