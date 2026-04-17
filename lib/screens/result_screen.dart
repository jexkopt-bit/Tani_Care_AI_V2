import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/constants.dart';

class ResultScreen extends ConsumerWidget {
  final String cropType;
  final String imagePath;

  const ResultScreen({super.key, required this.cropType, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Analysis is done in GeminiService - here we show result
    // (In real app you would pass the analysis result from scan_screen)

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Analisis'), backgroundColor: TaniCareColors.primaryGreen),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.file(File(imagePath), width: double.infinity, height: 320, fit: BoxFit.cover),
                Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 80, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54])))),
                Positioned(bottom: 16, left: 16, child: Text(cropType, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Analysis result would be passed here in real flow
                  const Text("Analisis sedang diproses oleh Gemini AI...", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan ke Log Ladang'),
                      style: ElevatedButton.styleFrom(backgroundColor: TaniCareColors.primaryGreen, foregroundColor: Colors.white),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('scans').add({
                          'crop': cropType,
                          'timestamp': FieldValue.serverTimestamp(),
                          'imageUrl': 'uploaded', // In real app upload image to Storage
                        });
                        Fluttertoast.showToast(msg: "✓ Disimpan ke Firestore");
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}