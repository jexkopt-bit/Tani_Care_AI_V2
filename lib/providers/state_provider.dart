import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared list of Malaysian states used across all screens
const List<String> malaysianStates = [
  'Johor',
  'Kedah',
  'Kelantan',
  'Melaka',
  'Negeri Sembilan',
  'Pahang',
  'Perak',
  'Perlis',
  'Pulau Pinang',
  'Sabah',
  'Sarawak',
  'Selangor',
  'Terengganu',
];

/// Shared list of crop types
const List<String> cropTypes = ['Padi', 'Sawit', 'Sayur', 'Buah', 'Getah'];

/// Global selected state — shared between Scan screen, Analytics screen, and Alerts screen
final selectedStateProvider = StateProvider<String>((ref) => 'Johor');

/// Global selected crop — shared between Scan and Analytics screens
final selectedCropProvider = StateProvider<String>((ref) => 'Padi');
