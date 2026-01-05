import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfilePictureService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Uri get _cloudinaryUrl => Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  final ImagePicker _imagePicker = ImagePicker();

  /// --- COMPRESSION LOGIC ---
  Future<Uint8List?> _compressImage(Uint8List list) async {
    try {
      return await FlutterImageCompress.compressWithList(
        list,
        minHeight: 512,
        minWidth: 512,
        quality: 80,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      debugPrint("Compression failed: $e");
      return list; // Fallback to original
    }
  }

  Future<dynamic> pickImage() async {
    try {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        return result?.files.first;
      } else {
        return await _imagePicker.pickImage(source: ImageSource.gallery);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<String?> uploadAndSaveImage({
    required String userId,
    required dynamic file,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _cloudinaryUrl);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['public_id'] = userId;

      Uint8List? finalBytes;

      if (kIsWeb && file is PlatformFile) {
        if (file.bytes == null) return null;
        finalBytes = await _compressImage(file.bytes!);
      } else if (file is XFile) {
        final bytes = await file.readAsBytes();
        finalBytes = await _compressImage(bytes);
      }

      if (finalBytes == null) return null;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        finalBytes,
        filename: 'pfp_$userId.jpg',
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) return null;

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['secure_url'];
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }
}