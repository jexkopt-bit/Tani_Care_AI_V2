import 'dart:convert';
import 'package:http/http.dart' as http;

class EarthEngineService {
  static const String _functionUrl = "https://earth-engine-alerts-asia-southeast1-tanicare-ai-2026.cloudfunctions.net/earth-engine-alerts";

  static Future<Map<String, dynamic>> getAnalytics({
    required String state,
    required String crop,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"state": state, "crop": crop}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          print("Backend error: ${data['error']}");
        }
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Earth Engine connection error: $e");
    }

    // Fallback indicating error state
    return {
      "current": {
        "ndvi": 0.0, 
        "evi": 0.0, 
        "risk": "Unknown", 
        "message": "Sila periksa sambungan internet anda atau cuba lagi nanti.", 
        "weather": "Data cuaca tidak tersedia"
      },
      "history": {
        "dates": List.generate(7, (index) => "N/A"),
        "ndvi": List.generate(7, (index) => 0.0),
        "evi": List.generate(7, (index) => 0.0)
      }
    };
  }
}