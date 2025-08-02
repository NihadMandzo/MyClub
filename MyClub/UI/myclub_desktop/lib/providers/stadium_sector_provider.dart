import 'package:myclub_desktop/models/stadium_sector.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class StadiumSectorProvider extends BaseProvider<StadiumSector> {
  StadiumSectorProvider() : super("StadiumSector");

  @override
  StadiumSector fromJson(data) {
    return StadiumSector.fromJson(data);
  }
}
