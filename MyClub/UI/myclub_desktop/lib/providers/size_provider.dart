import 'package:myclub_desktop/models/size.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class SizeProvider extends BaseProvider<Size> {
  SizeProvider() : super('Size');

  @override
  Size fromJson(data) {
    return Size.fromJson(data);
  }
}
