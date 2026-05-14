import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../../shared/models/travel_category.dart';
import '../../../travel_cards/presentation/controllers/travel_card_controller.dart';

class PlaceDetailSheet extends ConsumerWidget {
  final PlaceModel place;
  final RouteInfoModel? route;
  final String cardId;
  final PlaceVisitStatus status;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.cardId,
    required this.status,
    this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = TravelCategory.fromId(place.categoryId);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                  color: Colors.white.withOpacity(0.07), width: 1),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _PlaceHero(place: place, cat: cat),
                const SizedBox(height: 16),
                if (route != null) ...[
                  _RouteBar(route: route!),
                  const SizedBox(height: 14),
                ],
                _InfoChips(place: place),
                const SizedBox(height: 16),
                _AddressRow(address: place.address),
                if (place.reviews.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ReviewsSection(reviews: place.reviews),
                ],
                const SizedBox(height: 24),
                _ActionButtons(
                    place: place,
                    cardId: cardId,
                    status: status,
                    ref: ref),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _PlaceHero extends StatelessWidget {
  final PlaceModel place;
  final TravelCategory cat;
  const _PlaceHero({required this.place, required this.cat});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradientAt(
                  TravelCategory.values.indexOf(cat)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(cat.emoji,
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                const SizedBox(height: 4),
                Text(cat.label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFBF00), size: 16),
                    const SizedBox(width: 4),
                    Text(place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('(${place.reviewCount})',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}

// ─── Route bar ────────────────────────────────────────────────────────────────

class _RouteBar extends StatelessWidget {
  final RouteInfoModel route;
  const _RouteBar({required this.route});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _RouteChip(
                icon: Icons.straighten, label: route.distanceText),
            Container(
                width: 0.5, height: 20, color: AppTheme.border),
            _RouteChip(
                icon: Icons.access_time_outlined,
                label: route.durationText),
            Container(
                width: 0.5, height: 20, color: AppTheme.border),
            _RouteChip(
                icon: Icons.directions_car_outlined, label: 'Drive'),
          ],
        ),
      );
}

class _RouteChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RouteChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppTheme.primaryCyan, size: 15),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

// ─── Info chips ───────────────────────────────────────────────────────────────

class _InfoChips extends StatelessWidget {
  final PlaceModel place;
  const _InfoChips({required this.place});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(
            label: place.isOpenNow ? 'Open Now' : 'Closed',
            color:
                place.isOpenNow ? AppTheme.success : AppTheme.danger,
            icon: Icons.schedule_outlined,
          ),
          if (place.distanceMeters != null)
            _Chip(
              label: place.distanceMeters! < 1000
                  ? '${place.distanceMeters!.round()}m away'
                  : '${(place.distanceMeters! / 1000).toStringAsFixed(1)} km away',
              color: AppTheme.primaryCyan,
              icon: Icons.near_me_outlined,
            ),
          _Chip(
            label:
                '${place.reviewCount} reviews',
            color: const Color(0xFFFFBF00),
            icon: Icons.star_outline,
          ),
        ],
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Chip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── Address ─────────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final String address;
  const _AddressRow({required this.address});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: AppTheme.textSecondary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(address,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ],
      );
}

// ─── Reviews ─────────────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final List<PlaceReview> reviews;
  const _ReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reviews',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...reviews.map((r) => _ReviewCard(review: r)),
        ],
      );
}

class _ReviewCard extends StatelessWidget {
  final PlaceReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      review.author[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(review.author,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFFFBF00),
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(review.timeAgo,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.text,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      );
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final PlaceModel place;
  final String cardId;
  final PlaceVisitStatus status;
  final WidgetRef ref;

  const _ActionButtons({
    required this.place,
    required this.cardId,
    required this.status,
    required this.ref,
  });

  Future<void> _openExternal() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${place.lat},${place.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // ── In-app navigation (real turn-by-turn) ──────────────────────
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              context.go('/navigate/$cardId/${place.id}');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientTeal,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primaryCyan.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Start Navigation',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── External maps fallback ─────────────────────────────────────
          GestureDetector(
            onTap: _openExternal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new,
                      color: AppTheme.textSecondary, size: 15),
                  SizedBox(width: 6),
                  Text('Open in Google Maps',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (status != PlaceVisitStatus.visited)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(travelCardControllerProvider.notifier)
                          .markVisited(cardId, place.id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppTheme.success, size: 16),
                          SizedBox(width: 6),
                          Text('Mark Visited',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppTheme.success, size: 16),
                        SizedBox(width: 6),
                        Text('Visited ✓',
                            style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              if (status == PlaceVisitStatus.pending) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(travelCardControllerProvider.notifier)
                        .markSkipped(cardId, place.id);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.skip_next,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
}
