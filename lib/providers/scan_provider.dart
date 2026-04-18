// scan_provider.dart
// ─────────────────────────────────────────────────────────────────────────────
// MIGRATED: selectedCropProvider has moved to providers/state_provider.dart
// to be shared across all screens (Scan, Analytics, Alerts).
//
// Re-export from state_provider for backward compatibility.
// ─────────────────────────────────────────────────────────────────────────────
export 'state_provider.dart' show selectedCropProvider, selectedStateProvider;