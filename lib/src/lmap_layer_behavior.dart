import 'dart:math' as math;

import 'package:quiver/strings.dart' as str;

import 'lmap.dart';
import 'package:leaflet/src/base/evented.dart';
import 'package:leaflet/src/layers/layer.dart';
import 'package:leaflet/src/utility/helper.dart' as h;


typedef LayerHandlerFunc(dynamic context, Layer self);

abstract class LMapLayerBehavior {
  LMap _self;
  Map<String,Layer> _layers;
  Map<String, Layer> _zoomBoundLayers;

  Map<String, Layer> get layers => this._layers;

  initLayerBehavior(LMap map){
    this._self = map;
    this._layers = <String, Layer>{};
    this._zoomBoundLayers = <String, Layer>{};
  }

  addLayer(Layer layer){
    if (_layers.containsKey(layer.id)) {return;}

    _layers[layer.id] = layer;
    layer.mapToAdd = _self;
    layer.beforeAdd(_self);
    _self.whenReady(layer.layerAdd, layer);
  }

  removeLayer(Layer layer){
    if (!this._layers.containsKey(layer.id)) { return; }
    if(_self.loaded){
      layer.onRemove(_self);
    }

    if (str.isNotEmpty(layer.attribution) && this._self.attributionControl != null) {
			this._self.attributionControl.removeAttribution(layer.attribution);
		}

    if(_self.loaded){
      _self.fire('layerremove',new EventData(_self, {'layer': layer}));
      _self.fire('remove', new EventData(_self));
    }

    this._layers.remove(layer);
    layer.map = null;
    layer.mapToAdd = null;
  }

  bool hasLayer(Layer layer){
    return layer != null && this._layers.containsKey(layer.id);
  }

  eachLayer(LayerHandlerFunc func, dynamic context){
    for(Layer l in this._layers.values){
      func(context, l);
    }
  }

  addLayers(List<Layer> layers){
    layers = h.setOrDefault(layers, <Layer>[]);
    for(Layer l in layers){
      this.addLayer(l);
    }
  }

  addZoomLimit(Layer layer){
    if (layer.options.maxZoom.isNaN || !layer.options.minZoom.isNaN){
      this._zoomBoundLayers[layer.id] = layer;
      this._updateZoomLevels();
    }
  }

  removeZoomLimit(Layer layer){
    if (this._zoomBoundLayers.containsKey(layer.id)){
      this._zoomBoundLayers.remove(layer.id);
      this._updateZoomLevels();
    }
  }

  _updateZoomLevels(){
    double minZoom = double.infinity,
      maxZoom = double.negativeInfinity,
      oldZoomSpan = _self.getZoomSpan();

    for(Layer l in this._zoomBoundLayers.values){
      var options = l.options;
      minZoom = options.minZoom != null
          ? math.min(minZoom, options.minZoom)
          : minZoom;

      maxZoom = options.maxZoom != null
        ? math.max(maxZoom, options.maxZoom)
          : maxZoom;
    }

    _self.layersMaxZoom = maxZoom == double.negativeInfinity ? null : maxZoom;
    _self.layersMinZoom = minZoom == double.infinity ? null : minZoom;

    if(oldZoomSpan != _self.getZoomSpan()){
      _self.fire('zoomlevelschange', new EventData(_self));
    }

    if(_self.options.maxZoom == null && _self.layersMaxZoom != null && _self.zoom > _self.layersMaxZoom){
      _self.setZoom(_self.layersMaxZoom);
    }
    if(_self.options.minZoom == null && _self.layersMinZoom != null && _self.zoom  < _self.layersMinZoom){
      _self.setZoom(_self.layersMinZoom);
    }
  }
}