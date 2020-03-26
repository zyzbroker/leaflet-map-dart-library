import 'dart:html';

import 'package:quiver/strings.dart' as str;
import 'package:leaflet/src/utility/dom.dart' as dom;
import 'package:leaflet/src/lmap.dart';
import 'package:leaflet/src/controls/control.dart';
import 'package:leaflet/src/layers/layer.dart';

class Attribution extends Control {
  List<String> _attributions;

  Attribution() : super() {
    this.options.position = 'bottomright';
    this._attributions = <String>[];
  }

  @override
  onAdd(LMap map) {
    this.map = map;
    map.attributionControl = this;
    this.container = dom.createElement(
        tagName: 'div', className: 'leaflet-control-attribution');

    //todo: disable click propagation

    for (Layer layer in this.map.layers.values) {
      this.addAttribution(layer.attribution);
    }

    this._render();
  }

  set prefix(String prefix) {
    this.options.prefix = prefix;
    this._render();
  }

  addAttribution(String attributionText) {
    if (str.isEmpty(attributionText)) {
      return;
    }

    if (!this._attributions.contains(attributionText)) {
      this._attributions.add(attributionText);
    }

    this._render();
  }

  removeAttribution(String text) {
    if (str.isEmpty(text)) {
      return;
    }
    if (this._attributions.contains(text)) {
      this._attributions.remove(text);
    }
  }

  _render() {
    if (this.map == null) {
      return;
    }
    var content = <String>[];
    if (str.isNotEmpty(this.options.prefix)) {
      content.add(this.options.prefix);
    }
    if (this._attributions.isNotEmpty) {
      content.add(this._attributions.join(', '));
    }

    this._removeCopyRight();
    this.container.append(this._createResenTekLink());
    this.container.append(this._createTextElement(' | '));
    this.container.append(this._createLeafletLink());
    this.container.append(this._createTextElement(' &copy; '));
    this.container.append(this._createOpenStreetMapCopyRight());
  }

  void _removeCopyRight() {
    this.container.innerHtml = '';
  }

  HtmlElement _createTextElement(String content) {
    HtmlElement el = dom.createElement(tagName: 'span');
    el.innerHtml = content;
    return el;
  }

  HtmlElement _createLeafletLink() {
    return dom.createHyperLink(
        href: 'https://leafletjs.com/',
        title: 'Leaflet',
        html: 'leaflet',
        target: '__blank');
  }

  HtmlElement _createResenTekLink() {
    return dom.createHyperLink(
        href: 'http://www.resentek.com',
        title: 'ResentTek LLC',
        html: 'RensenTek LLC',
        target: '__blank');
  }

  HtmlElement _createOpenStreetMapCopyRight() {
    return dom.createHyperLink(
        href: 'http://www.openstreetmap.org/copyright',
        title: 'OpenStreetMap contributors',
        html: 'OpenStreetMap contributors',
        target: '__blank');
  }

  @override
  onRemove(LMap map) {
    // TODO: implement onRemove
    return null;
  }
}
