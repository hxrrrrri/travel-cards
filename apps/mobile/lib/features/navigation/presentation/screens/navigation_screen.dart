import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../../shared/models/travel_category.dart';
import '../../../travel_cards/presentation/controllers/travel_card_controller.dart';
import '../controllers/navigation_controller.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final String cardId;
  final String placeId;

  const NavigationScreen({
    super.key,
    required this.cardId,
    required this.placeId,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final _mapController = MapController();
  bool _mapReady = false;
  bool _followUser = true;

  PlaceModel? _place;
  RouteInfoModel? _route;

  @override
  void initState() {
    super.initState();
    _resolveData();
  }

  void _resolveData() {
    final cards = ref.read(travelCardControllerProvider).cards;
    final card = cards.where((c) => c.id == widget.cardId).firstOrNull;
    if (card == null) return;
    _place = card.discoveredPlaces.where((p) => p.id == widget.placeId).firstOrNull;
    _route = card.routes.where((r) => r.destinationPlaceId == widget.placeId).firstOrNull;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_place == null || _route == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text('Route not found. Go back and tap Navigate again.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final navState = ref.watch(
        navigationControllerProvider((_place!, _route!)));
    final controller = ref.read(
        navigationControllerProvider((_place!, _route!)).notifier);

    // Start tracking once
    if (navState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.start());
    }

    // Auto-center map on user position
    if (_mapReady && _followUser && navState.currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(navState.currentPosition!, 16.5);
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          _buildMap(navState),

          // ── Arrived overlay ────────────────────────────────────────────────
          if (navState.isArrived)
            _ArrivedOverlay(
              place: _place!,
              cardId: widget.cardId,
              ref: ref,
              onClose: () => context.go('/travel-cards/${widget.cardId}/map'),
            ),

          // ── Loading ────────────────────────────────────────────────────────
          if (navState.isLoading)
            Container(
              color: AppTheme.background,
              child: const LoadingWidget(message: 'Getting your location…'),
            ),

          // ── Error ──────────────────────────────────────────────────────────
          if (navState.error != null && !navState.isLoading)
            _ErrorBanner(message: navState.error!),

          // ── Instruction card (top) ─────────────────────────────────────────
          if (!navState.isArrived && !navState.isLoading)
            _InstructionCard(navState: navState),

          // ── Off-route banner ───────────────────────────────────────────────
          if (navState.isOffRoute && !navState.isArrived)
            const _OffRouteBanner(),

          // ── Bottom HUD ─────────────────────────────────────────────────────
          if (!navState.isArrived && !navState.isLoading)
            _BottomHud(
              navState: navState,
              onStop: () {
                controller.stop();
                context.go('/travel-cards/${widget.cardId}/map');
              },
              onToggleFollow: () => setState(() => _followUser = !_followUser),
              isFollowing: _followUser,
            ),

          // ── Re-center FAB ──────────────────────────────────────────────────
          if (!_followUser)
            Positioned(
              right: 16,
              bottom: 160,
              child: _GlassButton(
                icon: Icons.my_location,
                color: AppTheme.primaryCyan,
                onTap: () {
                  setState(() => _followUser = true);
                  if (navState.currentPosition != null) {
                    _mapController.move(navState.currentPosition!, 16.5);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(NavigationState navState) => FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _route!.polylinePoints.first,
          initialZoom: 15,
          backgroundColor: AppTheme.background,
          onMapReady: () => setState(() => _mapReady = true),
          onPositionChanged: (_, hasGesture) {
            if (hasGesture) setState(() => _followUser = false);
          },
        ),
        children: [
          // Dark map tiles
          TileLayer(
            urlTemplate: AppConstants.darkMapTileUrl,
            subdomains: AppConstants.mapSubdomains,
            userAgentPackageName: 'com.tripgraph.mobile',
          ),
          // Completed route (faded)
          if (navState.completedPolyline.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(
                points: navState.completedPolyline,
                strokeWidth: 5,
                color: AppTheme.routeInactive.withOpacity(0.4),
              ),
            ]),
          // Remaining route (bright)
          if (navState.remainingPolyline.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(
                points: navState.remainingPolyline,
                strokeWidth: 6,
                color: AppTheme.primaryCyan,
                gradientColors: const [
                  AppTheme.primaryCyan,
                  Color(0xFF7B52FF),
                ],
              ),
            ]),
          // Destination marker
          MarkerLayer(markers: [
            Marker(
              point: _route!.polylinePoints.last,
              width: 48,
              height: 48,
              child: _DestinationPin(place: _place!),
            ),
            // User position arrow
            if (navState.currentPosition != null)
              Marker(
                point: navState.currentPosition!,
                width: 56,
                height: 56,
                child: _UserArrow(heading: navState.currentHeading ?? 0),
              ),
          ]),
        ],
      );
}

// ─── Instruction card ─────────────────────────────────────────────────────────

class _InstructionCard extends StatelessWidget {
  final NavigationState navState;
  const _InstructionCard({required this.navState});

  @override
  Widget build(BuildContext context) {
    final step = navState.currentStep;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: step == null
                    ? const Text('Calculating route…',
                        style: TextStyle(color: AppTheme.textPrimary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Maneuver icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.gradientTeal,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(step.icon,
                                    color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.distanceText,
                                      style: const TextStyle(
                                          color: AppTheme.primaryCyan,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5),
                                    ),
                                    Text(
                                      step.instruction,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Next step preview
                          if (navState.nextStep != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              height: 0.5,
                              color: AppTheme.border,
                              margin: const EdgeInsets.only(bottom: 10),
                            ),
                            Row(
                              children: [
                                Icon(navState.nextStep!.icon,
                                    color: AppTheme.textSecondary, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Then: ${navState.nextStep!.instruction}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom HUD ───────────────────────────────────────────────────────────────

class _BottomHud extends StatelessWidget {
  final NavigationState navState;
  final VoidCallback onStop;
  final VoidCallback onToggleFollow;
  final bool isFollowing;

  const _BottomHud({
    required this.navState,
    required this.onStop,
    required this.onToggleFollow,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        bottom: 0, left: 0, right: 0,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(
                    top: BorderSide(
                        color: AppTheme.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  // Distance + ETA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          navState.distanceText,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time_outlined,
                                color: AppTheme.textSecondary, size: 13),
                            const SizedBox(width: 4),
                            Text(navState.etaText,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined,
                                color: AppTheme.textSecondary, size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                navState.destination.name,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stop button
                  GestureDetector(
                    onTap: onStop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.danger.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close,
                              color: AppTheme.danger, size: 18),
                          SizedBox(width: 6),
                          Text('End',
                              style: TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Arrived overlay ──────────────────────────────────────────────────────────

class _ArrivedOverlay extends StatelessWidget {
  final PlaceModel place;
  final String cardId;
  final WidgetRef ref;
  final VoidCallback onClose;

  const _ArrivedOverlay({
    required this.place,
    required this.cardId,
    required this.ref,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradientEmerald,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('You have arrived!',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(place.name,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    // Mark visited
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(travelCardControllerProvider.notifier)
                            .markVisited(cardId, place.id);
                        onClose();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.gradientEmerald,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppTheme.success.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Text('Mark as Visited',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                            textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text('Back to Map',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DestinationPin extends StatelessWidget {
  final PlaceModel place;
  const _DestinationPin({required this.place});

  @override
  Widget build(BuildContext context) {
    final cat = TravelCategory.fromId(place.categoryId);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.gradientPink,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppTheme.danger.withOpacity(0.4),
                  blurRadius: 12)
            ],
          ),
          child: Center(
              child: Text(cat.emoji,
                  style: const TextStyle(fontSize: 18))),
        ),
        CustomPaint(painter: _PinTailPainter(), size: const Size(12, 8)),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE91E7A);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UserArrow extends StatelessWidget {
  final double heading;
  const _UserArrow({required this.heading});

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: heading * 3.14159 / 180,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background,
            border: Border.all(color: AppTheme.primaryCyan, width: 3),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2)
            ],
          ),
          child: const Icon(Icons.navigation,
              color: AppTheme.primaryCyan, size: 28),
        ),
      );
}

class _OffRouteBanner extends StatelessWidget {
  const _OffRouteBanner();

  @override
  Widget build(BuildContext context) => Positioned(
        top: 140, left: 12, right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('You are off-route — continue to nearest road',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Positioned(
        top: 60, left: 12, right: 12,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.danger.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(message,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      );
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      );
}
