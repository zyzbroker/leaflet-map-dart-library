import 'dart:html';
import 'dart:svg';

class SvgNodeValidator implements NodeValidator {

  @override
  bool allowsElement(Element element) {
    return true;
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {

    if (element is SvgElement || element is TextElement || element is EllipseElement || element is GElement || element is RectElement){
      return true;
    }
    return false;
  }
}