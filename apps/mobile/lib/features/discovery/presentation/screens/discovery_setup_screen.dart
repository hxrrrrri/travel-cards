import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/env.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../shared/models/discovery_models.dart';
import '../../../../shared/models/travel_category.dart';
import '../../../travel_cards/presentation/controllers/travel_card_controller.dart';
import '../controllers/discovery_controller.dart';

class DiscoverySetupScreen extends ConsumerStatefulWidget {
  final String cardId;
  const DiscoverySetupScreen({super.key, required this.cardId});

  @override
  ConsumerState<DiscoverySetupScreen> createState() =>
      _DiscoverySetupScreenState();
}

class _DiscoverySetupScreenState extends ConsumerState<DiscoverySetupScreen> {
  double _radiusKm = 10.0;
  final Set<TravelCategory> _selected = {
    TravelCategory.cafe,
    TravelCategory.viewpoint,
    TravelCategory.touristAttraction,
    TravelCategory.waterfall,
  };
  double? _lat;
  double? _lng;
  String _locationName = '';
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (Env.demoMode) {
      setState(() {
        _lat = Env.demoLat;
        _lng = Env.demoLng;
        _locationName = Env.demoLocationName;
      });
      return;
    }
    await _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _lat = Env.demoLat;
          _lng = Env.demoLng;
          _locationName = '${Env.demoLocationName} (demo)';
          _locating = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationName =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _locating = false;
      });
    } catch (_) {
      setState(() {
        _lat = Env.demoLat;
        _lng = Env.demoLng;
        _locationName = '${Env.demoLocationName} (fallback)';
        _locating = false;
      });
    }
  }

  Future<void> _discover() async {
    if (_lat == null || _lng == null) return;

    await ref.read(travelCardControllerProvider.notifier).updateOrigin(
          widget.cardId,
          _lat!,
          _lng!,
          _locationName,
          (_radiusKm * 1000).round(),
          _selected.map((c) => c.id).toList(),
        );

    await ref.read(discoveryControllerProvider.notifier).discover(
          DiscoveryRequest(
            originLat: _lat!,
            originLng: _lng!,
            radiusMeters: (_radiusKm * 1000).round(),
            categories: _selected.map((c) => c.id).toList(),
            travelCardId: widget.cardId,
          ),
        );

    final discState = ref.read(discoveryControllerProvider);
    if (discState.status == DiscoveryStatus.success &&
        discState.response != null) {
      await ref.read(travelCardControllerProvider.notifier).updateDiscovery(
            widget.cardId,
            discState.response!.places,
            discState.response!.routes,
          );
    }

    if (!mounted) return;
    context.go('/travel-cards/${widget.cardId}/map');
  }

  @override
  Widget build(BuildContext context) {
    final discState = ref.watch(discoveryControllerProvider);
    final isLoading = discState.status == DiscoveryStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Places'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/travel-cards/${widget.cardId}'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LocationCard(
              locationName: _locationName,
              isLocating: _locating,
              onRefresh: _detectLocation,
            ),
            const SizedBox(height: 24),
            _RadiusSection(
              radiusKm: _radiusKm,
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
            const SizedBox(height: 24),
            _CategorySection(
              selected: _selected,
              onToggle: (cat) => setState(() {
                if (_selected.contains(cat)) {
                  if (_selected.length > 1) _selected.remove(cat);
                } else {
                  _selected.add(cat);
                }
              }),
            ),
            const SizedBox(height: 32),
            if (discState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Text(discState.error!,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
              ),
            AppButton(
              label: 'Generate Discovery Map',
              icon: Icons.explore,
              isLoading: isLoading || _locating,
              onPressed: _lat != null && !isLoading ? _discover : null,
            ),
            const SizedBox(height: 12),
            if (Env.demoMode)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text('Demo mode — using ${Env.demoLocationName}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String locationName;
  final bool isLocating;
  final VoidCallback onRefresh;

  const _LocationCard({
    required this.locationName,
    required this.isLocating,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location,
                  color: AppTheme.primaryCyan, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Location',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  isLocating
                      ? const SizedBox(
                          height: 16,
                          width: 80,
                          child: LinearProgressIndicator(
                              color: AppTheme.primaryCyan,
                              backgroundColor: AppTheme.border))
                      : Text(
                          locationName.isEmpty ? 'Detecting...' : locationName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: isLocating ? null : onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

class _RadiusSection extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  const _RadiusSection({required this.radiusKm, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Travel Radius',
                  style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryCyan.withOpacity(0.3)),
                ),
                child: Text(
                  '${radiusKm.round()} km',
                  style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${radiusKm.round()} km',
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1 km',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const Text('50 km',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      );
}

class _CategorySection extends StatelessWidget {
  final Set<TravelCategory> selected;
  final ValueChanged<TravelCategory> onToggle;

  const _CategorySection(
      {required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${selected.length} selected',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TravelCategory.values.map((cat) {
              final isSelected = selected.contains(cat);
              return FilterChip(
                selected: isSelected,
                label: Text('${cat.emoji} ${cat.label}'),
                onSelected: (_) => onToggle(cat),
                selectedColor: AppTheme.primaryCyan.withOpacity(0.15),
                checkmarkColor: AppTheme.primaryCyan,
                side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryCyan
                        : AppTheme.border),
                labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryCyan
                        : AppTheme.textSecondary,
                    fontSize: 12),
              );
            }).toList(),
          ),
        ],
      );
}
