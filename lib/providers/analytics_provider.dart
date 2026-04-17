import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../earth_engine_service.dart';

class AnalyticsState {
  final Map<String, dynamic> current;
  final Map<String, dynamic> history;

  AnalyticsState({required this.current, required this.history});

  List<String> get dates => (history['dates'] as List?)?.cast<String>() ?? [];
  List<double> get ndviList => (history['ndvi'] as List?)?.cast<double>() ?? [];
  List<double> get eviList => (history['evi'] as List?)?.cast<double>() ?? [];
  String get weather => current['weather'] ?? "Cuaca tidak tersedia";
  String get ndviCurrent => current['ndvi']?.toString() ?? "0.00";
  String get eviCurrent => current['evi']?.toString() ?? "0.00";
}

class AnalyticsNotifier extends AsyncNotifier<AnalyticsState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<AnalyticsState> build() async {
    return _fetchAndSave("Johor", "Padi");
  }

  Future<AnalyticsState> refresh(String state, String crop) async {
    final data = await _fetchAndSave(state, crop);
    return data;
  }

  Future<AnalyticsState> _fetchAndSave(String state, String crop) async {
    // Fetch from Earth Engine + Weather
    final rawData = await EarthEngineService.getAnalytics(state: state, crop: crop);

    final analyticsState = AnalyticsState(
      current: rawData['current'] ?? {},
      history: rawData['history'] ?? {},
    );

    // Save to Firestore (GCP)
    await _db.collection('analytics').doc('${state}_${crop}_${DateTime.now().millisecondsSinceEpoch}').set({
      'state': state,
      'crop': crop,
      'timestamp': FieldValue.serverTimestamp(),
      'ndvi': rawData['current']['ndvi'],
      'evi': rawData['current']['evi'],
      'weather': rawData['current']['weather'],
      'message': rawData['current']['message'],
    });

    return analyticsState;
  }
}

final analyticsProvider = AsyncNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  () => AnalyticsNotifier(),
);