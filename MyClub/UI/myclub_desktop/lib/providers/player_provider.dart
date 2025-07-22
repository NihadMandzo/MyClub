import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/player.dart';
import 'package:myclub_desktop/providers/base_provider.dart';
import 'package:http_parser/http_parser.dart';

class PlayerProvider extends BaseProvider<Player> {
  PlayerProvider() : super("Player");
  
  @override
  Player fromJson(data) {
    return Player.fromJson(data);
  }

  Future<Player> insertWithImage(Map<String, dynamic> request, List<int>? imageBytes, String? fileName) async {
    var url = "${BaseProvider.baseUrl}$endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    headers.remove('Content-Type'); // Remove content-type header for multipart request

    var request2 = http.MultipartRequest('POST', uri);
    request2.headers.addAll(headers);
    
    // Ensure all required fields are properly cased
    final mappedRequest = {
      'FirstName': request['firstName'] ?? '',
      'LastName': request['lastName'] ?? '',
      'Position': request['position'] ?? '',
      'Biography': request['biography'] ?? '',
      'Nationality': request['nationality'] ?? '',
      'Number': request['number']?.toString() ?? '0',
      'DateOfBirth': request['dateOfBirth'] ?? DateTime.now().toIso8601String(),
      'Height': request['height']?.toString() ?? '0',
      'Weight': request['weight']?.toString() ?? '0',
    };
    
    // Add form fields
    mappedRequest.forEach((key, value) {
      request2.fields[key] = value.toString();
    });
    
    // Add image if available
    if (imageBytes != null && fileName != null) {
      var multipartFile = http.MultipartFile.fromBytes(
        'ImageUrl',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', fileName.split('.').last),
      );
      request2.files.add(multipartFile);
    }
    
    var streamedResponse = await request2.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Greška tokom kreiranja igrača");
    }
  }
  
  Future<Player> updateWithImage(int id, Map<String, dynamic> request, List<int>? imageBytes, String? fileName) async {
    var url = "${BaseProvider.baseUrl}$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    headers.remove('Content-Type'); // Remove content-type header for multipart request

    var request2 = http.MultipartRequest('PUT', uri);
    request2.headers.addAll(headers);
    
    // Ensure all required fields are properly cased
    final mappedRequest = {
      'FirstName': request['firstName'] ?? '',
      'LastName': request['lastName'] ?? '',
      'Position': request['position'] ?? '',
      'Biography': request['biography'] ?? '',
      'Nationality': request['nationality'] ?? '',
      'Number': request['number']?.toString() ?? '0',
      'DateOfBirth': request['dateOfBirth'] ?? DateTime.now().toIso8601String(),
      'Height': request['height']?.toString() ?? '0',
      'Weight': request['weight']?.toString() ?? '0',
      'KeepPicture': request['keepPicture']?.toString() ?? 'false',
    };
    
    // Add form fields
    mappedRequest.forEach((key, value) {
      request2.fields[key] = value.toString();
    });
    
    // Add image if available
    if (imageBytes != null && fileName != null) {
      var multipartFile = http.MultipartFile.fromBytes(
        'ImageUrl',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', fileName.split('.').last),
      );
      request2.files.add(multipartFile);
    } else if (request['imageUrl'] != null) {
    }
    
    var streamedResponse = await request2.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Greška tokom editovanja igrača");
    }
  }
}
