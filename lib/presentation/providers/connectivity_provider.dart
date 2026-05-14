/// BBZCloud Mobile - Connectivity Provider
///
/// Streamt Online/Offline-Zustand aus `connectivity_plus`, damit die UI
/// (z.B. der OfflineBanner) auf Verbindungsverlust reagieren kann.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True solange das Geraet mindestens einen aktiven Transport hat
/// (WLAN, Mobilfunk, Ethernet, …). Wenn die Liste leer ist oder nur
/// `ConnectivityResult.none` enthaelt, ist das Geraet offline.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Initialer Zustand.
  yield _isOnline(await connectivity.checkConnectivity());

  // Updates beobachten.
  await for (final results in connectivity.onConnectivityChanged) {
    yield _isOnline(results);
  }
});

bool _isOnline(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}

/// Bequemer bool-Provider für UI-Code, die kein AsyncValue brauchen.
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityProvider);
  return async.maybeWhen(data: (v) => v, orElse: () => true);
});
