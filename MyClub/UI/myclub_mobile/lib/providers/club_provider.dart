import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myclub_mobile/models/responses/club_response.dart';
import 'package:myclub_mobile/providers/base_provider.dart';

class ClubProvider extends BaseProvider<ClubResponse> {
  ClubProvider() : super("Club");

  @override
  ClubResponse fromJson(data) {
    return ClubResponse.fromJson(data);
  }

}
