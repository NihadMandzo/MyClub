import 'package:myclub_desktop/models/stadium_side.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class StadiumSideProvider extends BaseProvider<StadiumSide> {
  StadiumSideProvider() : super("StadiumSide");

  @override
  StadiumSide fromJson(data) {
    return StadiumSide.fromJson(data);
  }
}
