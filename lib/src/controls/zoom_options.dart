import 'control_options.dart';

class ZoomOptions extends ControlOptions {
  String zoomInText;
  String zoomInTitle;
  String zoomOutText;
  String zoomOutTitle;

  ZoomOptions([String position = 'topleft']):super(){
    this.zoomInText = '+';
    this.zoomInTitle = 'Zoom in';
    this.zoomOutText = '&#x2212;';
    this.zoomOutTitle = 'Zoom out';
    this.position = position;
  }
}