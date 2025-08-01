import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myclub_desktop/models/membership_card.dart';
import 'package:myclub_desktop/providers/base_provider.dart';
import 'package:http_parser/http_parser.dart';

class MembershipCardProvider extends BaseProvider<MembershipCard> {
  MembershipCardProvider() : super("MembershipCard");
  
  @override
  MembershipCard fromJson(data) {
    return MembershipCard.fromJson(data);
  }

  Future<MembershipCard> insertWithImage(Map<String, dynamic> request, List<int>? imageBytes, String? fileName) async {
    var url = "${BaseProvider.baseUrl}$endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    headers.remove('Content-Type'); // Remove content-type header for multipart request

    var request2 = http.MultipartRequest('POST', uri);
    request2.headers.addAll(headers);
    
    // Ensure all required fields are properly cased
    final mappedRequest = {
      'Year': request['year']?.toString() ?? DateTime.now().year.toString(),
      'Name': request['name'] ?? '',
      'Description': request['description'] ?? '',
      'TargetMembers': request['targetMembers']?.toString() ?? '0',
      'Price': request['price']?.toString() ?? '0',
      'StartDate': request['startDate'] ?? DateTime.now().toIso8601String(),
      'EndDate': request['endDate'] ?? null,
      'Benefits': request['benefits'] ?? '',
      'IsActive': request['isActive']?.toString() ?? 'true',
    };
    
    // Add form fields
    mappedRequest.forEach((key, value) {
      if (value != null) {
        request2.fields[key] = value.toString();
      }
    });
    
    // Add image if available
    if (imageBytes != null && fileName != null) {
      var multipartFile = http.MultipartFile.fromBytes(
        'Image',
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
      throw Exception("Greška tokom kreiranja kampanje članstva");
    }
  }
  
  Future<MembershipCard> updateWithImage(int id, Map<String, dynamic> request, List<int>? imageBytes, String? fileName) async {
    var url = "${BaseProvider.baseUrl}$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    headers.remove('Content-Type'); // Remove content-type header for multipart request

    var request2 = http.MultipartRequest('PUT', uri);
    request2.headers.addAll(headers);
    

    // Validate required fields before sending
    if (request['name'] == null || request['name'].toString().isEmpty) {
      throw Exception("The Name field is required.");
    }
    
    if (request['description'] == null || request['description'].toString().isEmpty) {
      throw Exception("The Description field is required.");
    }
    
    if (request['benefits'] == null || request['benefits'].toString().isEmpty) {
      throw Exception("The Benefits field is required.");
    }
    
    double? price = double.tryParse(request['price']?.toString() ?? '0');
    if (price == null || price < 0.01) {
      throw Exception("The Price field must be greater than 0.01.");
    }
    
    // Check both keepImage and keepPicture fields for backward compatibility
    if (imageBytes == null && request['keepPicture'] != true && request['keepImage'] != true) {
      throw Exception("The Image field is required.");
    }
    
    // Ensure all required fields are properly cased
    final mappedRequest = {
      'Year': request['year']?.toString() ?? DateTime.now().year.toString(),
      'Name': request['name']?.toString() ?? '',
      'Description': request['description']?.toString() ?? '',
      'TargetMembers': request['targetMembers']?.toString() ?? '0',
      'Price': request['price']?.toString() ?? '0.01',
      'StartDate': request['startDate']?.toString() ?? DateTime.now().toIso8601String(),
      'EndDate': request['endDate']?.toString(),
      'Benefits': request['benefits']?.toString() ?? '',
      'IsActive': request['isActive']?.toString() ?? 'true',
      // Use keepPicture first, fall back to keepImage if needed
      'KeepImage': request['keepImage']?.toString() ?? 'false',
    };
    
    
    // Add form fields
    mappedRequest.forEach((key, value) {
      if (value != null) {
        request2.fields[key] = value.toString();
      }
    });
    
    // Add image if available
    if (imageBytes != null && fileName != null) {
      var multipartFile = http.MultipartFile.fromBytes(
        'Image',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', fileName.split('.').last),
      );
      request2.files.add(multipartFile);
    } else {
    }
    
    var streamedResponse = await request2.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Greška tokom ažuriranja kampanje članstva: ${response.body}");
    }
  }
}
