
import 'package:leaflet_map/src/lmap.dart';
import 'layer.dart';
import 'package:leaflet_map/src/base/evented.dart';
import 'layer_options.dart';
import 'package:leaflet_map/src/layers/grid_layer.dart';

class LayerGroup extends Layer {
  Map<String, Layer> _layers;

  LayerGroup(List<Layer> layers, [LayerOptions options = null]): super(options){
    this._layers = <String, Layer>{};
    for(Layer l in layers){
      this.addLayer(l);
    }
  }

  @override
  Map<String, EventFunc> getEvents() {
    return <String, EventFunc>{};
  }

  @override
  beforeAdd(LMap map) {
    this.map  = map;
  }

  @override
  onAdd(LMap map) {
    this.map = map;
    var keys = this._clonedKeys;
    for(String key in keys){
      map.addLayer(this._layers[key]);
    }
  }

  List<String> get _clonedKeys => this._layers.keys.toList();

  @override
  onRemove(LMap map) {
    var keys = this._clonedKeys;
    for(var key in keys){
      map.removeLayer(this._layers[key]);
    }
  }

  addLayer(Layer l){
    this._layers[l.id] = l;
    if (this.map != null){
      this.map.addLayer(l);
    }
  }

  removeLayer(Layer l) {
    if (this._layers.containsKey(l.id) && this.map != null){
      this.map.removeLayer(l);
    }

    this._layers.remove(l.id);
  }

  bool hasLayer(Layer l) => l != null && this._layers.containsKey(l.id);

  Layer getLayer(String id) => this._layers[id];

  List<Layer> get layers => this._layers.values.toList();

  setZIndex(num zIndex){
    for(Layer l in this._layers.values){
      if(l is GridLayer){
        l.setZIndex(zIndex);
      }
    }
  }
}