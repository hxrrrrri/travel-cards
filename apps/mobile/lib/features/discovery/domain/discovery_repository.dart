import '../../../shared/models/discovery_models.dart';

abstract class DiscoveryRepository {
  Future<DiscoveryResponse> discover(DiscoveryRequest request);
}
