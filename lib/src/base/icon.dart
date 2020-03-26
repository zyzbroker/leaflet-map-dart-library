import 'dart:html';

import 'package:quiver/strings.dart' as str;

import 'icon_options.dart';
import 'package:leaflet/src/utility/helper.dart' as h;
import 'point.dart' as p;

class Icon {
  IconOptions options;
  Icon(this.options);

  HtmlElement createIcon(HtmlElement oldIcon) {
    return this._createIcon('icon', oldIcon);
  }

  HtmlElement createShadow(HtmlElement oldIcon){
    return this._createIcon('shadow', oldIcon);
  }

  HtmlElement _createIcon(String name, HtmlElement oldIcon){
    String src = this.getUrl(name);
    if(str.isEmpty(src)){
      if (name == 'icon'){
        throw new Exception('iconUrl not set in icon options');
      }
      return null;
    }
    var img = this._createImg(src, name, oldIcon);
    this.setIconStyles(img, name);

    return img;
  }

  HtmlElement _createImg(String src, String name, HtmlElement oldIcon) {
    ImageElement img = (oldIcon != null && oldIcon is ImageElement)
        ? oldIcon
        : new ImageElement();
    img.src = src;
    return img;
  }


  setIconStyles(HtmlElement el, String name){
    bool isIcon = name == 'icon' ? true : false;
    p.Point size = isIcon ? this.options.iconSize : this.options.shadowSize;
    p.Point anchor = _getAnchor(name, size);

    h.addClass(el, 'leaflet-marker-' + name);

    if(str.isNotEmpty(this.options.className)){
      h.addClass(el, this.options.className);
    }

    if (anchor != null){
      el.style.marginLeft = '${-anchor.x}px';
      el.style.marginTop = '${-anchor.y}px';
    }

    if (size != null){
      el.style.width = '${size.x}px';
      el.style.height = '${size.y}px';
    }
  }


  p.Point _getAnchor(String name, p.Point size){
    if (name == 'shadow' && this.options.shadowAnchor != null){
      return this.options.shadowAnchor;
    } else if(this.options.iconAnchor != null) {
        return this.options.iconAnchor;
    } else if (size != null){
      return size * 0.5;
    }
    return null;
  }


  String getUrl(String name){
    switch(name){
      case 'icon':
        return this._getIconUrl();
      case 'shadow':
        return this._getShadowIconUrl();
      default:
        return '';
    }
  }

  String _getIconUrl(){
    return h.retina ? this.options.iconRetinaUrl : this.options.iconUrl;
  }

  String _getShadowIconUrl(){
    return this.options.shadowUrl;
  }
}