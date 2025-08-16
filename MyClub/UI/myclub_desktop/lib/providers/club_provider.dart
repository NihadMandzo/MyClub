import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/club.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class ClubProvider extends BaseProvider<Club> {
  ClubProvider() : super("Club");

  @override
  Club fromJson(data) {
    return Club.fromJson(data);
  }


  Future<Club?> updateClub(int id, String name, String description, File? logoImage, {
    DateTime? establishedDate,
    String? stadiumName,
    String? stadiumLocation,
    int? numberOfTitles,
  }) async {
    var url = "${BaseProvider.baseUrl}$endpoint/$id";
    var uri = Uri.parse(url);
    
    var request = http.MultipartRequest('PUT', uri);
    
    // Add headers
    var headers = createHeaders();
    request.headers.addAll(headers);
    
    // Add text fields
    request.fields['id'] = id.toString();
    request.fields['name'] = name;
    request.fields['description'] = description;
    
    // Add optional fields
    if (establishedDate != null) {
      request.fields['establishedDate'] = establishedDate.toIso8601String();
    }
    
    if (stadiumName != null) {
      request.fields['stadiumName'] = stadiumName;
    }
    
    if (stadiumLocation != null) {
      request.fields['stadiumLocation'] = stadiumLocation;
    }
    
    if (numberOfTitles != null) {
      request.fields['numberOfTitles'] = numberOfTitles.toString();
    }
    
    // Add file if provided
    if (logoImage != null) {
      var stream = http.ByteStream(logoImage.openRead());
      var length = await logoImage.length();
      
      var multipartFile = http.MultipartFile(
        'logoImage',
        stream,
        length,
        filename: logoImage.path.split('/').last
      );
      
      request.files.add(multipartFile);
    }
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    }
    
    return null;
  }
}
