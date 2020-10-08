import 'package:leaflet_map/src/lmap.dart';
import 'package:leaflet_map/src/lmap_options.dart';
import 'package:leaflet_map/src/layers/tile_layer.dart';
import 'package:leaflet_map/src/layers/layer_options.dart';
import 'package:leaflet_map/src/layers/marker.dart';
import 'package:leaflet_map/src/utility/helper.dart' as h;
import 'package:leaflet_map/icons.dart';
import 'package:leaflet_map/src/controls/zoom.dart';

main() {
  LMap map = new LMap('#mapContainer', new LMapOptions()
    ..maxZoom = 18.0
    ..setView = true
  );

  //add zoom control
  Zoom.create('topright').addTo(map);

  LayerOptions options = new LayerOptions.tileDefault();
  options.maxZoom = 18.0;
  options.attribution =
  '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>';
  new TileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', options)
      .addTo(map);

  try{
    var markers = _getMarkers();
    for(var mk in markers){
      mk.addTo(map);
    }

    var latLngList = getProperties().map((d)=>h.toLatLng([d['lat'],d['lng']])).toList();
    var bounds = h.getLatLngBounds(latLngList);

    map.fitBounds(bounds);
  } catch(ex){
    h.dumpError(ex);
  }

}

void onMarkerClick(dynamic index){
  print('----index:$index----');
}

Icon genDivIcon(num id, String title, String detail){
    var soldColor = '#228b22',
        saleColor = '#dc3545';
    String color = title.contains('Sold') ? soldColor : saleColor;

  return new IndexedSvgIcon.create(id.toString(), color);
}



List<Marker> _getMarkers() {
  var markers = <Marker>[];
  var props = getProperties();
  int index = 1;
  props.forEach((p)=> p['id'] = index++);
  for(var p in props){
    markers.add(new Marker([p['lat'], p['lng']])
      ..customData = p['id']
      ..onMarkerClick = onMarkerClick
      ..icon= genDivIcon(p['id'], p['title'], p['detail']));
  }
  return markers;
}


List<Map<String, Object>> getProperties() =>
    [
      {
        'id': 1,
        'lat': 32.877035,
        'lng': -97.203181,
        'title': 'For Sale',
        'detail': '7113 Brookhaven Ct  North Richland Hills, TX 76182'
      }, {
        'id': 2,
        'lat': 32.894492,
        'lng': -96.793616,
        'title': 'Sold',
        'detail': '6466 Royal Ln  Dallas, TX 75230'
      }, {
        'id': 3,
        'lat': 32.896346,
        'lng': -97.302785,
        'title': 'Sold',
        'detail': '3928 Cane River Rd  Fort Worth, TX 76244'
      }, {
        'id': 4,
        'lat': 32.843959,
        'lng': -97.177658,
        'title': 'Sold',
        'detail': '452 Hillview Dr Hurst, TX 76054'
      }, {
        'id': 5,
        'lat': 32.874742,
        'lng': -97.167788,
        'title': 'Sold',
        'detail': '106 Bremen Dr  Hurst, TX 76054'
      }, {
        'id': 5,
        'lat': 32.834001,
        'lng': -97.076789,
        'title': 'Sold',
        'detail': '406 Martin Ln  Euless, TX 76040'
      }, {
        'id': 5,
        'lat': 32.794743,
        'lng': -97.189571,
        'title': 'Sold',
        'detail': '8732 Saranac Trl  Fort Worth, TX 76118'
      }, {
        'id': 5,
        'lat': 33.026938,
        'lng': -97.067887,
        'title': 'Sold',
        'detail': '3005 Brookhollow Ln Flower Mound, TX 75028'
      }, {
        'id': 5,
        'lat': 33.101020,
        'lng': -96.860669,
        'title': 'Sold',
        'detail': '5825 Poole Dr  The Colony, TX 75056'
      }, {
        'id': 5,
        'lat': 32.806761,
        'lng': -97.198665,
        'title': 'Sold',
        'detail': '8344 Edgepoint Trl  Hurst, TX 76053'
      }, {
        'id': 5,
        'lat': 32.871966,
        'lng': -97.250515,
        'title': 'Sold',
        'detail': '6044 Ridgecrest Dr  Watauga, TX 76148'
      }];