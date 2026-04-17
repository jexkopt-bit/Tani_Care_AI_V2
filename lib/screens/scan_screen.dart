import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../providers/scan_provider.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCrop = ref.watch(selectedCropProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Imbas Tanaman'), backgroundColor: TaniCareColors.primaryGreen),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [TaniCareColors.background, Colors.white])),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(shape: BoxShape.circle, color: TaniCareColors.primaryGreen.withOpacity(0.1)),
                child: Icon(Icons.camera_alt_rounded, size: 120, color: TaniCareColors.primaryGreen),
              ),
              const SizedBox(height: 40),
              const Text("Ambil Gambar Daun atau Batang", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: DropdownButtonFormField<String>(
                  value: selectedCrop,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: ['Padi', 'Sawit', 'Sayur', 'Buah'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => ref.read(selectedCropProvider.notifier).state = val!,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text('Ambil Gambar Sekarang', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: TaniCareColors.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (photo != null && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(cropType: selectedCrop, imagePath: photo.path)));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}