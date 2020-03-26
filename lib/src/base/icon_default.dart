import 'icon.dart';
import 'icon_options.dart';
import 'package:quiver/strings.dart' as str;

class IconDefault extends Icon {
  String imagePath;

  IconDefault(IconOptions options):super(options);

  factory IconDefault.fromDefault() {
    IconOptions options = new IconOptions.defaultOption();
    return new IconDefault(options);
  }

  String getUrl(String name)=> path + super.getUrl(name);

  String get path => str.isNotEmpty(this.imagePath) ? this.imagePath : this.options.imagePath;
}