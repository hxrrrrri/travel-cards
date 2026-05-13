import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/discovery_models.dart';
import '../../data/discovery_repository_impl.dart';
import '../../domain/discovery_repository.dart';

enum DiscoveryStatus { idle, loading, success, error }

class DiscoveryState {
  final DiscoveryStatus status;
  final DiscoveryResponse? response;
  final String? error;

  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.response,
    this.error,
  });

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    DiscoveryResponse? response,
    String? error,
  }) =>
      DiscoveryState(
        status: status ?? this.status,
        response: response ?? this.response,
        error: error,
      );
}

class DiscoveryController extends StateNotifier<DiscoveryState> {
  final DiscoveryRepository _repo;

  DiscoveryController(this._repo) : super(const DiscoveryState());

  Future<void> discover(DiscoveryRequest request) async {
    state = state.copyWith(status: DiscoveryStatus.loading);
    try {
      final response = await _repo.discover(request);
      state = state.copyWith(
          status: DiscoveryStatus.success, response: response);
    } catch (e) {
      state = state.copyWith(
          status: DiscoveryStatus.error, error: e.toString());
    }
  }

  void reset() => state = const DiscoveryState();
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
    (_) => DiscoveryRepositoryImpl());

final discoveryControllerProvider =
    StateNotifierProvider<DiscoveryController, DiscoveryState>(
        (ref) => DiscoveryController(ref.read(discoveryRepositoryProvider)));
