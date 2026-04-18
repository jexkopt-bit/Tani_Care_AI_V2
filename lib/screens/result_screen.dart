import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/constants.dart';
import '../gemini_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String cropType;
  final String imagePath;
  final String state; // ✅ Dynamic state for dialect + weather

  const ResultScreen({
    super.key,
    required this.cropType,
    required this.imagePath,
    required this.state,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  String? _analysisResult;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await GeminiService.analyzeCrop(
        imagePath: widget.imagePath,
        cropType: widget.cropType,
        state: widget.state,
      );
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResult = 'Ralat semasa analisis: $e';
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Analisis AI'),
        backgroundColor: TaniCareColors.primaryGreen,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Analisis semula',
              onPressed: _runAnalysis,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Image Hero ────────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  color: Colors.black87,
                  height: 320,
                  width: double.infinity,
                  child: kIsWeb
                      ? Image.network(
                          widget.imagePath,
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          io.File(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cropType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.state,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Agent Pipeline Indicator ──────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: TaniCareColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy,
                            size: 16, color: TaniCareColors.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '5 Sub-Agen AI: Diagnosis · Cuaca · RAG · ROI · Undang-undang',
                            style: TextStyle(
                              fontSize: 11,
                              color: TaniCareColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Analysis Result ───────────────────────────────────
                  if (_isLoading) ...[
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Sub-agen AI sedang menganalisis...\nDiagnosis · Cuaca · RAG · ROI · Undang-undang',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _analysisResult ?? 'Ralat tidak diketahui',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        _analysisResult ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Save to Firestore ─────────────────────────────────
                  if (!_isLoading)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan ke Log Ladang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaniCareColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('scans')
                              .add({
                            'crop': widget.cropType,
                            'state': widget.state,
                            'analysis': _analysisResult,
                            'timestamp': FieldValue.serverTimestamp(),
                            'imageUrl': 'local:${widget.imagePath}',
                          });
                          Fluttertoast.showToast(
                              msg: '✓ Disimpan ke Log Ladang (Firestore)');
                          if (context.mounted) {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          }
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