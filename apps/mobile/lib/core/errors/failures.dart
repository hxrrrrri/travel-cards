abstract class Failure {
  final String message;
  const Failure(this.message);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Location permission denied or unavailable']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Local storage error']);
}

class DiscoveryFailure extends Failure {
  const DiscoveryFailure([super.message = 'Discovery failed']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}
