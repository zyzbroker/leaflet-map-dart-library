import 'dart:html';
import 'dart:svg';
import 'package:quiver/strings.dart' as str;

HtmlElement createElement({String tagName, String className, HtmlElement container}) {
  HtmlElement e = document.createElement(tagName);
  if(str.isNotEmpty(className)){
    List<String> classes = className.split(' ');
    e.classes.addAll(classes);
  }

  if(container != null){
    container.append(e);
  }
  return e;
}

SvgElement createSVG(String name){
  return new SvgElement.tag(name);
}

AnchorElement createHyperLink({String href, String title, String className, String target, String html}){
  AnchorElement el = createElement(tagName: 'a', className: className);
  el.href = str.isNotEmpty(href) ? href : '#';
  el.title = title;
  el.target = target;
  el.innerHtml = html;
  return el;
}