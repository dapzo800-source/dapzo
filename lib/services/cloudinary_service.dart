import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads images to Cloudinary using an UNSIGNED upload preset.
/// No Cloudinary API secret is ever stored in the Flutter app — only the
/// cloud name + a restricted unsigned preset configured in the Cloudinary
/// dashboard (folder-scoped, size-limited).
class CloudinaryService {
  // TODO: replace with your real Cloudinary cloud name (find it at the top
  // of your Cloudinary dashboard — looks like 'dxyz123abc'). Never put the
  // API secret here; only the cloud name and unsigned preset name belong
  // in client code.
  static const String cloudName = 'dxyz123abc';
  static const String uploadPreset = 'meet_dapzo';

  /// [folder] should be one of: products, categories, shops, offers, profiles
  /// per the meet_dapzo/ Cloudinary structure.
  Future<String?> uploadImage(File imageFile, {required String folder}) async {
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
    return null;
  }
}