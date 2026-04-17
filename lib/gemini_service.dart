import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class GeminiService {
  // Use 10.0.2.2 for Android Emulator, or localhost for iOS/Web.
  // In production, this will be your Google Cloud Run URL.
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8080/analyze',
  );

  static Future<String> analyzeCrop({
    required String imagePath,
    required String cropType,
  }) async {
    try {
      final imageBytes = await img.decodeImageFile(imagePath);
      if (imageBytes == null) {
        return "Ralat: Gagal membaca gambar.";
      }
      
      final jpegBytes = await compute(_processImage, imageBytes);
      final base64Image = base64Encode(jpegBytes);

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': base64Image,
          'crop_type': cropType,
          'state': 'Johor' // This could be passed dynamically in the future
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? "Maaf, tiada hasil analisis.";
      } else {
        return "Ralat Pelayan: ${response.statusCode}";
      }
    } catch (e) {
      return "Ralat: $e";
    }
  }

  static Uint8List _processImage(img.Image image) {
    final resized = img.copyResize(image, width: 1024);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
