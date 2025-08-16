import 'package:myclub_desktop/models/position.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class PositionProvider extends BaseProvider<Position> {
  PositionProvider() : super("Position");

  @override
  Position fromJson(data) {
    return Position.fromJson(data);
  }
}
