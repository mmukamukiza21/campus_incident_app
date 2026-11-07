
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'xcqpm7yx';
  static const String uploadPreset = 'campus_incidents';

  static Future<String> uploadImage(Uint8List imageBytes) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'campus_incidents'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename:
              'incident_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final result = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (result is Map) {
        final secureUrl = result['secure_url'];

        if (secureUrl is String && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }

      throw Exception('Cloudinary did not return an image URL.');
    }

    String? message;

    if (result is Map) {
      final uploadError = result['error'];

      if (uploadError is Map) {
        message = uploadError['message']?.toString();
      }
    }

    throw Exception(
      message ?? 'Image upload failed. Please try again.',
    );
  }
}
