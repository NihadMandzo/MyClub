import 'package:myclub_desktop/models/color.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class ColorProvider extends BaseProvider<Color> {
  ColorProvider() : super('Color');

  @override
  Color fromJson(data) {
    return Color.fromJson(data);
  }
}
