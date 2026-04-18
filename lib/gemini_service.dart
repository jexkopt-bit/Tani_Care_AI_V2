import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class GeminiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator / Web.
  // In production, set BACKEND_URL to your Google Cloud Run URL via --dart-define.
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://tanicare-genkit-backend-672367571031.us-central1.run.app/analyze',
  );

  /// Analyzes a crop image by calling the TaniCare Multi-Agent backend.
  static Future<String> analyzeCrop({
    required String imagePath,
    required String cropType,
    required String state,
  }) async {
    try {
      Uint8List bytes;
      if (kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob')) {
        final response = await http.get(Uri.parse(imagePath));
        bytes = response.bodyBytes;
      } else {
        final file = io.File(imagePath);
        bytes = await file.readAsBytes();
      }

      // Resize + compress image in a background isolate (passing only serializable bytes)
      final jpegBytes = await compute(_processImage, bytes);
      final base64Image = base64Encode(jpegBytes);

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': base64Image,
          'crop_type': cropType,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? 'Maaf, tiada hasil analisis diterima.';
      } else {
        return 'Ralat Pelayan: ${response.statusCode}. Sila cuba lagi.';
      }
    } catch (e) {
      return 'Ralat sambungan: $e';
    }
  }

  /// Compresses and resizes image in background isolate to avoid UI jank.
  static Uint8List _processImage(Uint8List inputBytes) {
    final image = img.decodeImage(inputBytes);
    if (image == null) return Uint8List(0);
    
    // Increased resolution to 2048px for better detail handling by Vision AI
    // Adjusted quality to 90% for a cleaner "Full Size" experience
    final resized = img.copyResize(image, width: 2048);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }
}
