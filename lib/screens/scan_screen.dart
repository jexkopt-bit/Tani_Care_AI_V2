import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';
import '../utils/constants.dart';
import '../providers/state_provider.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCrop = ref.watch(selectedCropProvider);
    final selectedState = ref.watch(selectedStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imbas Tanaman'),
        backgroundColor: TaniCareColors.primaryGreen,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TaniCareColors.background, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Camera icon hero
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TaniCareColors.primaryGreen.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 120,
                  color: TaniCareColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ambil Gambar Daun atau Batang',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'AI akan menganalisis dalam dialek tempatan anda',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Crop Type Dropdown ─────────────────────────────────────────
              _buildDropdown(
                label: 'Jenis Tanaman',
                icon: Icons.grass,
                value: selectedCrop,
                items: cropTypes,
                onChanged: (val) =>
                    ref.read(selectedCropProvider.notifier).state = val!,
              ),
              const SizedBox(height: 12),

              // ── Malaysian State Dropdown ───────────────────────────────────
              _buildDropdown(
                label: 'Negeri Anda',
                icon: Icons.location_on,
                value: selectedState,
                items: malaysianStates,
                onChanged: (val) =>
                    ref.read(selectedStateProvider.notifier).state = val!,
              ),

              const Spacer(),

              // ── Capture Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text(
                    'Ambil Gambar Sekarang',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TaniCareColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (photo != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            cropType: selectedCrop,
                            imagePath: photo.path,
                            state: selectedState, // ✅ Pass selected state
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Gallery fallback button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih dari Galeri'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TaniCareColors.primaryGreen,
                    side: BorderSide(color: TaniCareColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (photo != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            cropType: selectedCrop,
                            imagePath: photo.path,
                            state: selectedState,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable styled dropdown widget
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: TaniCareColors.primaryGreen, size: 20),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}