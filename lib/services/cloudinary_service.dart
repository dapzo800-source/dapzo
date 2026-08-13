import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Uploads images to Cloudinary using an UNSIGNED upload preset.
class CloudinaryService {
  String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// [folder] should be one of: products, categories, shops, offers, profiles
  /// per the meet_dapzo/ Cloudinary structure.
  Future<String?> uploadImage(File imageFile, {required String folder}) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloudinary environment variables missing in .env file');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'meet_dapzo/$folder'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['secure_url'] as String?;
    }

    String message = 'Cloudinary upload failed (${response.statusCode})';
    try {
      final data = jsonDecode(body);
      final errMsg = data['error']?['message'];
      if (errMsg != null) message = '$message: $errMsg';
    } catch (_) {
      // Body wasn't JSON
    }
    throw Exception(message);
  }
}