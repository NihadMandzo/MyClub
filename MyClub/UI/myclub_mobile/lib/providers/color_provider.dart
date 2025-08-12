import '../models/responses/color_response.dart';
import 'base_provider.dart';

class ColorProvider extends BaseProvider<ColorResponse> {
  ColorProvider() : super("Color");

  @override
  ColorResponse fromJson(data) {
    return ColorResponse.fromJson(data);
  }
}
