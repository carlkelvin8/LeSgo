/// Thrown when a mutating request is queued because the device is offline.
class OfflineQueuedException implements Exception {
  const OfflineQueuedException();
}
