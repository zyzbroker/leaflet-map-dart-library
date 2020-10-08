import 'dart:html';

import 'package:leaflet_map/src/utility/dom.dart' as dom;
import 'package:leaflet_map/src/base/point.dart' as p;
import 'package:leaflet_map/src/base/icon_options.dart';
import 'package:leaflet_map/src/base/icon.dart';
import 'svg_node_validator.dart';

class IndexedSvgIcon extends Icon {
  static final String _className = 'rst-div-icon';
  static final List<String> _markerTextX = ['40', '34', '26'];
  static final String _svgTemplate = '''
      <svg 
        xmlns:svg="http://www.w3.org/2000/svg" 
        xmlns="http://www.w3.org/2000/svg" 
        width="32" 
        height="32" 
        viewBox="0 0 31.999999 31.999999">
        <g transform="matrix(0.49994211,0,0,0.35779738,-7.6311526,-341.26742)">
          <ellipse 
            style="opacity:1;fill:{color};fill-opacity:0.99215686;stroke:#131409;stroke-width:0;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:1;stroke-dasharray:none;stroke-opacity:1" 
              id="path3336-6-6-7" cx="47.388901" cy="988.88934" rx="31.85413" ry="34.286339" />  
          <rect 
            style="opacity:1;fill:{color};fill-opacity:0.99215686;stroke:#131409;stroke-width:0;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:1;stroke-dasharray:none;stroke-opacity:1" 
            id="rect3338-7-2-0" width="41.129089" height="41.294788" x="-582.5202" y="672.4411" 
            transform="matrix(0.61993853,-0.78465038,0.56988721,0.82172292,0,0)" />
          <ellipse 
            style="opacity:1;fill:#ffffff;fill-opacity:0.99215686;stroke:#131409;stroke-width:0;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:1;stroke-dasharray:none;stroke-opacity:1" 
            id="path3342-5-9-9" cx="47.781197" cy="987.47705" rx="23.459074" ry="23.929829" />  
          <text xml:space="preserve" alignment-baseline="central" x="{x}" y="990" linespacing="125%">{content}</text>
        </g>
      </svg>
    ''';

  IndexedSvgIcon._(IconOptions options):super(options);

  factory IndexedSvgIcon.create(String index, String color){
    IconOptions options = new IconOptions()
      ..className = 'leaflet-div-icon $_className'
      ..iconSize = new p.Point(12, 12);

    options.html = _genHtml(index, color);

    IndexedSvgIcon svgIcon = new IndexedSvgIcon._(options);
    return svgIcon;
  }

  static String _genHtml(String index, String color) {
    return _svgTemplate.replaceAll('{color}', color)
        .replaceAll('{content}', index)
        .replaceAll('{x}', _markerTextX[_calculateTextX(index)]);
  }

  static num _calculateTextX(String id){
    var x = 0, len = id.length;
    if(len == 2){
      x = 1;
    } else if (len < 2){
      x = 0;
    } else {
      x = 2;
    }
    return x;
  }

  @override
  HtmlElement createIcon(HtmlElement oldIcon) {
    AnchorElement el = (oldIcon is AnchorElement) ? oldIcon : dom.createElement(tagName: 'a', className: this.options.className);

    el.href='javascript:void(0);';
    el.setInnerHtml(this.options.html, validator: new SvgNodeValidator());

    if (this.options.backgroundPosition != null){
      var pos = this.options.backgroundPosition;
      el.style.backgroundPosition = '${-pos.x}px ${-pos.y}px';
    }

    this.setIconStyles(el, 'icon');
    return el;
  }

  @override
  HtmlElement createShadow(HtmlElement oldIcon) {
    return null;
  }
}