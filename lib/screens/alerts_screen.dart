import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../utils/constants.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Amaran'), backgroundColor: TaniCareColors.primaryGreen),
      body: analyticsAsync.when(
        data: (state) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 1,
          itemBuilder: (context, index) {
            final alert = state.current;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert['title'] ?? "Amaran Tanaman", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(alert['message'] ?? ""),
                    const SizedBox(height: 16),
                    Text("Cadangan: ${alert['action'] ?? 'Teruskan pemantauan'}", style: TextStyle(color: TaniCareColors.primaryGreen, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text("Gagal memuat amaran")),
      ),
    );
  }
}