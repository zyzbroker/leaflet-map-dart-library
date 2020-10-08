import 'layer_options.dart';
import 'package:leaflet_map/src/base/icon.dart';
import 'package:leaflet_map/src/base/icon_default.dart';
import 'package:tuple/tuple.dart';

class MarkerOptions extends LayerOptions {
  Icon icon;
  bool interactive;
  bool draggable;
  bool autoPan;
  Tuple2<int,int> autoPanPadding;
  num autoPanSpeed;
  bool keyboard;
  String title;
  String alt;
  num zIndexOffset;
  bool riseOnHover;
  num riseOffset;

  MarkerOptions():super() {
    this.draggable = false;
    this.pane = 'markerPane';
    this.icon = new IconDefault.fromDefault();
    this.interactive = true;
    this.autoPanPadding = new Tuple2(50,50);
    this.autoPanSpeed = 10;
    this.keyboard = true;
    this.riseOffset = 250;
    this.bubblingMouseEvents = false;
    this.autoPan = false;
    this.title = '';
    this.alt = '';
    this.zIndexOffset = 0;
    this.opacity = 1;
    this.riseOnHover = false;
  }
}
