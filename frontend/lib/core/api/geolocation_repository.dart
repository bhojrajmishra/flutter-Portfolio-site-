import 'package:geolocator/geolocator.dart';

/// Thrown when the visitor's location can't be determined (permission
/// denied, timed out, location services off, etc) — callers should show a
/// graceful fallback rather than crash.
class LocationUnavailable implements Exception {
  final String message;
  const LocationUnavailable(this.message);
  @override
  String toString() => message;
}

class GeolocationRepository {
  /// Requests the browser/device's current position directly — on web this
  /// alone triggers the native permission prompt if not yet granted/denied,
  /// so there's no separate check/request pre-flight needed (and skipping
  /// it avoids relying on the Permissions API, which resolves unreliably
  /// under some automated/embedded browser contexts). Hard-capped with an
  /// explicit timeout so a stalled permission prompt or platform quirk
  /// fails fast into the UI's fallback state instead of hanging forever.
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw const LocationUnavailable('Location request timed out.'),
    ).catchError((Object e) {
      if (e is LocationUnavailable) throw e;
      throw LocationUnavailable('Location unavailable: $e');
    });
  }
}
