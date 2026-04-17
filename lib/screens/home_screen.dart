import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../utils/constants.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaniCare AI'),
        backgroundColor: TaniCareColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(analyticsProvider.future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [TaniCareColors.primaryGreen, TaniCareColors.lightGreen]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text("Jexko-1Bit", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text("Kawan Petani, Penjaga Tanaman", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              analyticsAsync.when(
                data: (state) {
                  final current = state.current;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wb_sunny, color: Colors.orange, size: 32),
                              const SizedBox(width: 12),
                              Expanded(child: Text(current['weather'] ?? "Cuaca tidak tersedia", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _metric("NDVI", current['ndvi']?.toString() ?? "0.52", TaniCareColors.primaryGreen),
                              _metric("EVI", current['evi']?.toString() ?? "0.41", TaniCareColors.accentOrange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text("Gagal memuat data"),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text('Imbas Tanaman Sekarang', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TaniCareColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(children: [Text(label, style: const TextStyle(fontSize: 14)), Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color))]);
  }
}