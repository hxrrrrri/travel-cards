import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../../shared/models/travel_category.dart';
import '../../../travel_cards/presentation/controllers/travel_card_controller.dart';
import '../widgets/place_detail_sheet.dart';
import '../widgets/place_node_marker.dart';
import '../widgets/route_layer.dart';

class DiscoveryMapScreen extends ConsumerStatefulWidget {
  final String cardId;
  const DiscoveryMapScreen({super.key, required this.cardId});

  @override
  ConsumerState<DiscoveryMapScreen> createState() =>
      _DiscoveryMapScreenState();
}

class _DiscoveryMapScreenState extends ConsumerState<DiscoveryMapScreen> {
  final _mapController = MapController();
  String? _selectedPlaceId;
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPlaceTap(PlaceModel place, TravelCardModel card) {
    setState(() => _selectedPlaceId = place.id);
    _mapController.move(LatLng(place.lat, place.lng), 13.5);

    final route =
        card.routes.where((r) => r.destinationPlaceId == place.id).firstOrNull;
    final status =
        card.placeStatuses[place.id] ?? PlaceVisitStatus.pending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => PlaceDetailSheet(
        place: place,
        route: route,
        cardId: card.id,
        status: status,
      ),
    ).then((_) => setState(() => _selectedPlaceId = null));
  }

  void _zoomToFit(TravelCardModel card) {
    if (!_mapReady || card.discoveredPlaces.isEmpty) return;
    final lats = [card.originLat!, ...card.discoveredPlaces.map((p) => p.lat)];
    final lngs = [card.originLng!, ...card.discoveredPlaces.map((p) => p.lng)];
    final bounds = LatLngBounds(
      LatLng(lats.reduce((a, b) => a < b ? a : b) - 0.01,
          lngs.reduce((a, b) => a < b ? a : b) - 0.01),
      LatLng(lats.reduce((a, b) => a > b ? a : b) + 0.01,
          lngs.reduce((a, b) => a > b ? a : b) + 0.01),
    );
    _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelCardControllerProvider);
    final card = state.cards.where((c) => c.id == widget.cardId).firstOrNull;

    if (state.isLoading || card == null) {
      return const Scaffold(body: LoadingWidget(message: 'Loading map…'));
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(card),
          _TopOverlay(
              card: card,
              onBack: () => context.go('/travel-cards/${card.id}')),
          _BottomPanel(card: card),
          _MapControls(
            onFit: () => _zoomToFit(card),
            onZoomIn: () => _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1),
            onZoomOut: () => _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TravelCardModel card) => FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(card.originLat!, card.originLng!),
          initialZoom: 11.5,
          backgroundColor: AppTheme.background,
          onMapReady: () {
            setState(() => _mapReady = true);
            Future.delayed(
                const Duration(milliseconds: 300), () => _zoomToFit(card));
          },
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.darkMapTileUrl,
            subdomains: AppConstants.mapSubdomains,
            userAgentPackageName: 'com.tripgraph.mobile',
            retinaMode: true,
          ),
          RouteLayer(
            routes: card.routes,
            selectedPlaceId: _selectedPlaceId,
            placeStatuses: card.placeStatuses,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(card.originLat!, card.originLng!),
                width: 56,
                height: 56,
                child: const OriginMarker(),
              ),
              ...card.discoveredPlaces.map(
                (p) => Marker(
                  point: LatLng(p.lat, p.lng),
                  width: _selectedPlaceId == p.id ? 60 : 52,
                  height: _selectedPlaceId == p.id ? 60 : 52,
                  child: PlaceNodeMarker(
                    place: p,
                    status: card.placeStatuses[p.id] ??
                        PlaceVisitStatus.pending,
                    isSelected: _selectedPlaceId == p.id,
                    onTap: () => _onPlaceTap(p, card),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

// ─── Top overlay ──────────────────────────────────────────────────────────────

class _TopOverlay extends StatelessWidget {
  final TravelCardModel card;
  final VoidCallback onBack;
  const _TopOverlay({required this.card, required this.onBack});

  @override
  Widget build(BuildContext context) => Positioned(
        top: 0, left: 0, right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                _GlassButton(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppTheme.textPrimary, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.07)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: AppTheme.gradientTeal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.route,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                card.title,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (card.originName != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryCyan.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(card.radiusMeters / 1000).round()} km',
                                  style: const TextStyle(
                                      color: AppTheme.primaryCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Bottom panel ─────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final TravelCardModel card;
  const _BottomPanel({required this.card});

  @override
  Widget build(BuildContext context) => Positioned(
        bottom: 24, left: 16, right: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.07), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatPill(
                      icon: Icons.place_outlined,
                      value: '${card.discoveredCount}',
                      label: 'Found',
                      color: AppTheme.primaryCyan),
                  Container(
                      width: 0.5, height: 28,
                      color: AppTheme.border),
                  _StatPill(
                      icon: Icons.check_circle_outline,
                      value: '${card.visitedCount}',
                      label: 'Visited',
                      color: AppTheme.success),
                  Container(
                      width: 0.5, height: 28,
                      color: AppTheme.border),
                  _StatPill(
                      icon: Icons.schedule_outlined,
                      value: '${card.pendingCount}',
                      label: 'Pending',
                      color: AppTheme.accentOrange),
                ],
              ),
            ),
          ),
        ),
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPill(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10)),
            ],
          ),
        ],
      );
}

// ─── Map controls ─────────────────────────────────────────────────────────────

class _MapControls extends StatelessWidget {
  final VoidCallback onFit;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  const _MapControls(
      {required this.onFit,
      required this.onZoomIn,
      required this.onZoomOut});

  @override
  Widget build(BuildContext context) => Positioned(
        bottom: 20, right: 16,
        child: Column(
          children: [
            _GlassButton(onTap: onFit,
                child: const Icon(Icons.fit_screen,
                    color: AppTheme.primaryCyan, size: 20)),
            const SizedBox(height: 8),
            _GlassButton(onTap: onZoomIn,
                child: const Icon(Icons.add,
                    color: AppTheme.textPrimary, size: 20)),
            const SizedBox(height: 8),
            _GlassButton(onTap: onZoomOut,
                child: const Icon(Icons.remove,
                    color: AppTheme.textPrimary, size: 20)),
          ],
        ),
      );
}

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      );
}
