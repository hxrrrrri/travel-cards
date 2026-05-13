import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/glass_card.dart';
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

    final route = card.routes
        .where((r) => r.destinationPlaceId == place.id)
        .firstOrNull;
    final status =
        card.placeStatuses[place.id] ?? PlaceVisitStatus.pending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
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
    final lats = [
      card.originLat!,
      ...card.discoveredPlaces.map((p) => p.lat)
    ];
    final lngs = [
      card.originLng!,
      ...card.discoveredPlaces.map((p) => p.lng)
    ];
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
      return const Scaffold(body: LoadingWidget(message: 'Loading map...'));
    }

    final originLat = card.originLat!;
    final originLng = card.originLng!;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(card, originLat, originLng),
          _TopBar(card: card, onBack: () => context.go('/travel-cards/${card.id}')),
          _buildBottomPanel(card),
          _buildFab(card),
        ],
      ),
    );
  }

  Widget _buildMap(TravelCardModel card, double oLat, double oLng) =>
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(oLat, oLng),
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
            tileBuilder: _darkTileBuilder,
          ),
          RouteLayer(
            routes: card.routes,
            selectedPlaceId: _selectedPlaceId,
            placeStatuses: card.placeStatuses,
          ),
          MarkerLayer(
            markers: [
              // Origin marker
              Marker(
                point: LatLng(oLat, oLng),
                width: 56,
                height: 56,
                child: const OriginMarker(),
              ),
              // Place markers
              ...card.discoveredPlaces.map(
                (p) => Marker(
                  point: LatLng(p.lat, p.lng),
                  width: _selectedPlaceId == p.id ? 60 : 52,
                  height: _selectedPlaceId == p.id ? 60 : 52,
                  child: PlaceNodeMarker(
                    place: p,
                    status:
                        card.placeStatuses[p.id] ?? PlaceVisitStatus.pending,
                    isSelected: _selectedPlaceId == p.id,
                    onTap: () => _onPlaceTap(p, card),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _darkTileBuilder(
          BuildContext ctx, Widget tile, TileImage tileImage) =>
      ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -0.2126, -0.7152, -0.0722, 0, 255,
          -0.2126, -0.7152, -0.0722, 0, 255,
          -0.2126, -0.7152, -0.0722, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: tile,
      );

  Widget _buildBottomPanel(TravelCardModel card) => Positioned(
        bottom: 100,
        left: 16,
        right: 16,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                  icon: Icons.place,
                  value: '${card.discoveredCount}',
                  label: 'Found',
                  color: AppTheme.primaryCyan),
              _Divider(),
              _StatChip(
                  icon: Icons.check_circle,
                  value: '${card.visitedCount}',
                  label: 'Visited',
                  color: AppTheme.success),
              _Divider(),
              _StatChip(
                  icon: Icons.schedule,
                  value: '${card.pendingCount}',
                  label: 'Pending',
                  color: AppTheme.accentOrange),
            ],
          ),
        ),
      );

  Widget _buildFab(TravelCardModel card) => Positioned(
        bottom: 172,
        right: 16,
        child: Column(
          children: [
            FloatingActionButton.small(
              heroTag: 'zoom_fit',
              onPressed: () => _zoomToFit(card),
              backgroundColor: AppTheme.surfaceElevated,
              foregroundColor: AppTheme.primaryCyan,
              child: const Icon(Icons.fit_screen, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'zoom_in',
              onPressed: () =>
                  _mapController.move(_mapController.camera.center,
                      _mapController.camera.zoom + 1),
              backgroundColor: AppTheme.surfaceElevated,
              foregroundColor: AppTheme.textPrimary,
              child: const Icon(Icons.add, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'zoom_out',
              onPressed: () =>
                  _mapController.move(_mapController.camera.center,
                      _mapController.camera.zoom - 1),
              backgroundColor: AppTheme.surfaceElevated,
              foregroundColor: AppTheme.textPrimary,
              child: const Icon(Icons.remove, size: 20),
            ),
          ],
        ),
      );
}

class _TopBar extends StatelessWidget {
  final TravelCardModel card;
  final VoidCallback onBack;

  const _TopBar({required this.card, required this.onBack});

  @override
  Widget build(BuildContext context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 14,
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppTheme.textPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.route,
                            color: AppTheme.primaryCyan, size: 18),
                        const SizedBox(width: 8),
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
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppTheme.primaryCyan.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${(card.radiusMeters / 1000).round()} km',
                              style: const TextStyle(
                                  color: AppTheme.primaryCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppTheme.border);
}
