import 'dart:async';
import 'package:leaflet/src/utility/helper.dart' as h;
import 'package:leaflet/src/base/evented.dart';

class Throttle {
  bool _lock = false;
  int _time;
  Timer _timer;
  EventFunc _func;
  dynamic _context;
  AppEvent _appEvent;


  Throttle(this._func, this._time);

  void run([dynamic context, AppEvent appEvent]){

     if(this._lock) {
       this._context = context;
       this._appEvent = appEvent;
       return;
     }
     this._lock = true;
     this._func(this._context, this._appEvent);
     this._timer = new Timer(new Duration(milliseconds: this._time), this._later);
  }

  _later(){
    this._func(this._context, this._appEvent);
    this._lock = false;
  }

  cancel() {
    if(this._timer != null && this._timer.isActive){
      this._timer.cancel();
      this._timer = null;
    }
  }
}