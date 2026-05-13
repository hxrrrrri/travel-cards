import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/env.dart';
import '../../../../app/theme.dart';
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

class _DiscoverySetupScreenState
    extends ConsumerState<DiscoverySetupScreen> {
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
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
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
    final cats = _selected.map((c) => c.id).toList();

    await ref.read(travelCardControllerProvider.notifier).updateOrigin(
          widget.cardId, _lat!, _lng!, _locationName,
          (_radiusKm * 1000).round(), cats);

    await ref.read(discoveryControllerProvider.notifier).discover(
          DiscoveryRequest(
            originLat: _lat!,
            originLng: _lng!,
            radiusMeters: (_radiusKm * 1000).round(),
            categories: cats,
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
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(
              child: CustomPaint(
                  painter: _DotPainter())),
          Positioned(
            top: -60,
            left: -60,
            child: _GlowBlob(
                color: AppTheme.primaryCyan.withOpacity(0.07), size: 250),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () =>
                    context.go('/travel-cards/${widget.cardId}')),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _LocationCard(
                          locationName: _locationName,
                          isLocating: _locating,
                          onRefresh: _detectLocation,
                        ),
                        const SizedBox(height: 20),
                        _RadiusCard(
                          radiusKm: _radiusKm,
                          onChanged: (v) => setState(() => _radiusKm = v),
                        ),
                        const SizedBox(height: 20),
                        _CategoriesSection(
                          selected: _selected,
                          onToggle: (cat) => setState(() {
                            if (_selected.contains(cat)) {
                              if (_selected.length > 1) _selected.remove(cat);
                            } else {
                              _selected.add(cat);
                            }
                          }),
                        ),
                        if (discState.error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: discState.error!),
                        ],
                        const SizedBox(height: 24),
                        AppButton(
                          label: isLoading
                              ? 'Discovering…'
                              : 'Generate Discovery Map',
                          icon: Icons.explore,
                          isLoading: isLoading || _locating,
                          onPressed:
                              _lat != null && !isLoading ? _discover : null,
                        ),
                        if (Env.demoMode) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 13,
                                  color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Demo — ${Env.demoLocationName}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.textPrimary, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Setup Discovery',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Text('Choose what to discover',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}

// ─── Location card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final String locationName;
  final bool isLocating;
  final VoidCallback onRefresh;
  const _LocationCard(
      {required this.locationName,
      required this.isLocating,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientTeal,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.my_location,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Location',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 3),
                  isLocating
                      ? const SizedBox(
                          height: 14,
                          child: LinearProgressIndicator(
                              color: AppTheme.primaryCyan,
                              backgroundColor: AppTheme.border))
                      : Text(
                          locationName.isEmpty ? 'Detecting…' : locationName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isLocating ? null : onRefresh,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.refresh,
                    color: AppTheme.textSecondary, size: 18),
              ),
            ),
          ],
        ),
      );
}

// ─── Radius card ──────────────────────────────────────────────────────────────

class _RadiusCard extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;
  const _RadiusCard({required this.radiusKm, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Travel Radius',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${radiusKm.round()} km',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                const Text('50 km',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      );
}

// ─── Categories ───────────────────────────────────────────────────────────────

class _CategoriesSection extends StatelessWidget {
  final Set<TravelCategory> selected;
  final ValueChanged<TravelCategory> onToggle;
  const _CategoriesSection(
      {required this.selected, required this.onToggle});

  // Map each category to a gradient
  static const _catGradients = {
    'cafe': AppTheme.gradientAmber,
    'restaurant': AppTheme.gradientPink,
    'viewpoint': AppTheme.gradientTeal,
    'tourist_attraction': AppTheme.gradientPurple,
    'park': AppTheme.gradientEmerald,
    'bio_park': AppTheme.gradientEmerald,
    'museum': AppTheme.gradientPurple,
    'hotel': AppTheme.gradientTeal,
    'fuel_station': AppTheme.gradientSlate,
    'shopping': AppTheme.gradientAmber,
    'temple': AppTheme.gradientPink,
    'beach': AppTheme.gradientTeal,
    'waterfall': AppTheme.gradientTeal,
  };

  @override
  Widget build(BuildContext context) {
    final cats = TravelCategory.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Categories',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${selected.length} selected',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: cats.length,
          itemBuilder: (_, i) {
            final cat = cats[i];
            final isOn = selected.contains(cat);
            final gradient =
                _catGradients[cat.id] ?? AppTheme.gradientSlate;
            return GestureDetector(
              onTap: () => onToggle(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: isOn ? gradient : null,
                  color: isOn ? null : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isOn
                        ? Colors.transparent
                        : AppTheme.border,
                  ),
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                              color: AppTheme.primaryCyan.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat.emoji,
                        style: TextStyle(
                            fontSize: isOn ? 26 : 22)),
                    const SizedBox(height: 5),
                    Text(
                      cat.label,
                      style: TextStyle(
                        color: isOn
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.danger.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.danger, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppTheme.danger, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color,
                blurRadius: size,
                spreadRadius: size * 0.4)
          ],
        ),
      );
}

class _DotPainter extends CustomPainter {
  const _DotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A2A);
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
