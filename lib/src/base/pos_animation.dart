import 'dart:math' as math;
import 'dart:html';

import 'point.dart' as p;
import 'evented.dart';
import 'package:leaflet/src/utility/helper.dart' as h;

class PosAnimation extends Evented {
  num _animId;
  HtmlElement _el;
  bool _inProgress = false;
  double _duration;
  double _easeOutPower;
  p.Point _startPos;
  p.Point _offset;
  DateTime _startTime;

  run(HtmlElement el, p.Point newPos, double duration, [num easeLinearity]){
    this.stop();
    this._el = el;
    this._inProgress = true;
    this._duration = duration != null ? duration : 0.25;
    this._easeOutPower = 1 / math.max(easeLinearity != null ? easeLinearity : 0.5, 0.2);
    this._startPos = h.getPosition(el);
    this._offset = newPos - this._startPos;
    this._startTime = new DateTime.now();

    this.fire('start');
    this._animate();
  }

  stop(){
    if (this._inProgress == false) {return;}
    this._step(true);
    this._complete();
  }


  _animate([num highResoluteTime]){
    this._animId = window.requestAnimationFrame(this._animate);
    this._step();
  }

  _step([bool round = false]){
    var elapsed = new DateTime.now().difference(this._startTime).inMilliseconds,
      duration = this._duration * 1000;

    if(elapsed < duration){
      this._runFrame(this._easeOut(elapsed / duration), round);
    } else {
      this._runFrame(1.0, round);
      this._complete();
    }
  }

  _runFrame(double progress, bool round){
    p.Point pos = this._offset * progress + this._startPos;
    if(round){
      pos = pos.round();
    }
    h.setPosition(this._el, pos);
    this.fire('step');
  }

  _complete(){
    h.cancelAnimFrame(this._animId);
    this._inProgress = false;
    this.fire('end');
  }

  double _easeOut(double t){
    return 1 - math.pow(1 - t, this._easeOutPower);
  }

}