import '../models/responses/size_response.dart';
import 'base_provider.dart';

class SizeProvider extends BaseProvider<SizeResponse> {
  SizeProvider() : super("Size");

  @override
  SizeResponse fromJson(data) {
    return SizeResponse.fromJson(data);
  }
}
