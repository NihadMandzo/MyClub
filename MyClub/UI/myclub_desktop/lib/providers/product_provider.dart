import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:myclub_desktop/models/product.dart';
import 'package:myclub_desktop/models/product_size.dart';
import 'package:myclub_desktop/providers/base_provider.dart';

class ProductProvider extends BaseProvider<Product> {
  ProductProvider() : super("Product");
  
  @override
  Product fromJson(data) {
    return Product.fromJson(data);
  }

  Future<Product> insertWithImage(Map<String, dynamic> request, List<List<int>> imagesBytesList, List<String> fileNames, List<ProductSize> productSizes) async {
    var url = "${BaseProvider.baseUrl}$endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    headers.remove('Content-Type'); // Remove content-type header for multipart request

    var request2 = http.MultipartRequest('POST', uri);
    request2.headers.addAll(headers);
    
    // Ensure all required fields are properly cased
    final mappedRequest = {
      'Name': request['name'] ?? '',
      'Description': request['description'] ?? '',
      'BarCode': request['barCode'] ?? '',
      'Price': request['price']?.toString() ?? '0',
      'ColorId': request['colorId']?.toString() ?? '0',
      'CategoryId': request['categoryId']?.toString() ?? '0',
      'IsActive': request['isActive']?.toString() ?? 'true',
    };
    
    // Add form fields
    mappedRequest.forEach((key, value) {
      request2.fields[key] = value.toString();
    });
    
    // Add images
    for (var i = 0; i < imagesBytesList.length; i++) {
      var multipartFile = http.MultipartFile.fromBytes(
        'Images',
        imagesBytesList[i],
        filename: fileNames[i],
        contentType: MediaType('image', fileNames[i].split('.').last),
      );
      request2.files.add(multipartFile);
    }
    
    // Add product sizes
    if (productSizes.isNotEmpty) {
      for (var i = 0; i < productSizes.length; i++) {
        request2.fields['ProductSizes[$i].SizeId'] = productSizes[i].size?.id.toString() ?? '';
        request2.fields['ProductSizes[$i].Quantity'] = productSizes[i].quantity.toString();
      }
    }
    
    var streamedResponse = await request2.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Error creating product");
    }
  }
  
  Future<Product> updateWithImage(int id, Map<String, dynamic> request, List<List<int>>? imagesBytesList, List<String>? fileNames, List<int>? imagesToKeep, List<ProductSize> productSizes) async {
    var url = "${BaseProvider.baseUrl}$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    headers.remove('Content-Type'); // Remove content-type header for multipart request

    var request2 = http.MultipartRequest('PUT', uri);
    request2.headers.addAll(headers);
    
    // Ensure all required fields are properly cased
    final mappedRequest = {
      'Name': request['name'] ?? '',
      'Description': request['description'] ?? '',
      'BarCode': request['barCode'] ?? '',
      'Price': request['price']?.toString() ?? '0',
      'ColorId': request['colorId']?.toString() ?? '0',
      'CategoryId': request['categoryId']?.toString() ?? '0',
      'IsActive': request['isActive']?.toString() ?? 'true',
    };
    
    // Add form fields
    mappedRequest.forEach((key, value) {
      request2.fields[key] = value.toString();
    });
    
    // Add images if available
    if (imagesBytesList != null && fileNames != null) {
      for (var i = 0; i < imagesBytesList.length; i++) {
        var multipartFile = http.MultipartFile.fromBytes(
          'Images',
          imagesBytesList[i],
          filename: fileNames[i],
          contentType: MediaType('image', fileNames[i].split('.').last),
        );
        request2.files.add(multipartFile);
      }
    }
    
    // Add images to keep
    if (imagesToKeep != null && imagesToKeep.isNotEmpty) {
      for (var i = 0; i < imagesToKeep.length; i++) {
        request2.fields['ImagesToKeep[$i]'] = imagesToKeep[i].toString();
      }
    }
    
    // Add product sizes
    if (productSizes.isNotEmpty) {
      for (var i = 0; i < productSizes.length; i++) {
        request2.fields['ProductSizes[$i].SizeId'] = productSizes[i].size?.id.toString() ?? '';
        request2.fields['ProductSizes[$i].Quantity'] = productSizes[i].quantity.toString();
      }
    }
    
    var streamedResponse = await request2.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Error updating product");
    }
  }
}
