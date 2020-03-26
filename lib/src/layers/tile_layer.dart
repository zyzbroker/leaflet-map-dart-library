import 'dart:html';
import 'grid_layer.dart';
import 'layer_options.dart';
import 'package:leaflet/src/base/point.dart' as p;
import 'package:leaflet/src/utility/helper.dart' as h;
import 'package:leaflet/src/base/evented.dart';


class TileLayer extends GridLayer {
  String _url;

  TileLayer(this._url, [LayerOptions options]):super(options) {
    this.options = options == null ? new LayerOptions.tileDefault() : options;
  }

  setUrl(String url, [bool noRedraw = true]) {
    this._url = url;
    if (!noRedraw) {
      this.redraw();
    }
  }

  HtmlElement createTile(p.Point coords){
      ImageElement tile = new ImageElement();
      if(this.options.crossOrigin == true){
        tile.crossOrigin = '';
      }

      tile.alt = '';
      tile.setAttribute('role', 'presentation');
      tile.src = this.getTileUrl(coords);

      return tile;
  }

  String getTileUrl(p.Point<num> coords){
    Map<String,String> data = <String,String>{
      'r': h.retina ? '@2x' : '',
      's': this._getSubDomain(coords),
      'x': coords.x.toString(),
      'y': coords.y.toString(),
      'z': this._getZoomForUrl().toString()
    };

    if(this.map != null && this.map.options.crs.infinite != true){
      var invertedY = this.globalTileRange.max.y - coords.y;
      if(this.options.tms){
        data['y'] = invertedY.toString();
      } else {
        data['-y'] = invertedY.toString();
      }
    }

    return h.template(this._url, h.extend(data, this.options.toMap()));
  }

  String _getSubDomain(p.Point<num> tilePoint){
    int index = (tilePoint.x + tilePoint.y).abs() % this.options.subDomains.length;
    return this.options.subDomains[index];
  }

  num _getZoomForUrl(){
    var zoom = this.tileZoom,
      maxZoom = this.options.maxZoom,
      zoomReverse = this.options.zoomReverse,
      zoomOffset = this.options.zoomOffset;

    if(zoomReverse == true){
      zoom = maxZoom - zoom;
    }
    return zoom + zoomOffset;
  }

}