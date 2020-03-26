import 'point.dart';

class IconOptions {
  String iconUrl;
  String iconRetinaUrl;
  String shadowUrl;
  Point backgroundPosition;
  Point iconSize;
  Point iconAnchor;
  Point popupAnchor;
  Point shadowAnchor;
  Point tooltipAnchor;
  Point shadowSize;
  String className = '';
  String imagePath = '';
  String html = '';

  IconOptions():
      popupAnchor = new Point(0, 0),
      tooltipAnchor = new Point(0, 0);

  IconOptions.defaultOption() {
    this.iconUrl = '/assets/images/marker-icon.png';
    this.iconRetinaUrl = '/assets/images/marker-icon-2x.png';
    this.shadowUrl = '/assets/images/marker-shadow.png';
    this.iconSize = new Point(25,41);
    this.iconAnchor = new Point(12,41);
    this.popupAnchor = new Point(1, -34);
    this.tooltipAnchor = new Point(16, -28);
    this.shadowSize = new Point(41,41);
  }

}