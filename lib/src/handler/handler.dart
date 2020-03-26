import 'package:leaflet/src/lmap.dart';

abstract class Handler {
  bool _enabled = false;
  LMap map;

  Handler(this.map);

  bool get enabled => this._enabled;

  addHooks();
  removeHooks();

  void enable() {
    if(!this._enabled){
      this._enabled = true;
      this.addHooks();
    }
  }

  void disable() {
    if(this._enabled){
      this._enabled = false;
      this.removeHooks();
    }
  }
}