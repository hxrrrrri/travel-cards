import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/haversine.dart';
import '../../../../core/widgets/app_button.dart';
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
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PlaceHeader(place: place, cat: cat),
            const SizedBox(height: 16),
            if (route != null) _RouteInfoRow(route: route!),
            const SizedBox(height: 16),
            _InfoRow(Icons.location_on_outlined, place.address),
            if (place.isOpenNow)
              const _InfoRow(Icons.access_time, 'Open Now', valueColor: AppTheme.success)
            else
              const _InfoRow(Icons.access_time, 'Closed', valueColor: AppTheme.danger),
            const SizedBox(height: 20),
            if (place.reviews.isNotEmpty) ...[
              Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...place.reviews.map((r) => _ReviewTile(review: r)),
              const SizedBox(height: 16),
            ],
            _ActionButtons(
              place: place,
              cardId: cardId,
              status: status,
              ref: ref,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceHeader extends StatelessWidget {
  final PlaceModel place;
  final TravelCategory cat;

  const _PlaceHeader({required this.place, required this.cat});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: Text(cat.emoji, style: const TextStyle(fontSize: 26)),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(cat.label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.accentOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('(${place.reviewCount} reviews)',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}

class _RouteInfoRow extends StatelessWidget {
  final RouteInfoModel route;

  const _RouteInfoRow({required this.route});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _RouteChip(Icons.straighten, route.distanceText),
            Container(width: 1, height: 20, color: AppTheme.border),
            _RouteChip(Icons.access_time, route.durationText),
            Container(width: 1, height: 20, color: AppTheme.border),
            _RouteChip(Icons.directions_car, 'By car'),
          ],
        ),
      );
}

class _RouteChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RouteChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppTheme.primaryCyan, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.icon, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: valueColor ?? AppTheme.textSecondary,
                      fontSize: 13)),
            ),
          ],
        ),
      );
}

class _ReviewTile extends StatelessWidget {
  final PlaceReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(review.author,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                ...List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.accentOrange,
                          size: 12,
                        )),
                const SizedBox(width: 6),
                Text(review.timeAgo,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(review.text,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
}

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

  Future<void> _navigate() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${place.lat},${place.lng}'
        '&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AppButton(
            label: 'Start Navigation',
            icon: Icons.navigation,
            onPressed: _navigate,
            color: AppTheme.primaryCyan,
          ),
          const SizedBox(height: 10),
          if (status != PlaceVisitStatus.visited)
            AppButton(
              label: 'Mark as Visited',
              icon: Icons.check_circle_outline,
              outlined: true,
              color: AppTheme.success,
              onPressed: () {
                ref
                    .read(travelCardControllerProvider.notifier)
                    .markVisited(cardId, place.id);
                Navigator.pop(context);
              },
            )
          else
            AppButton(
              label: 'Visited ✓',
              icon: Icons.check_circle,
              outlined: true,
              color: AppTheme.success,
              onPressed: null,
            ),
          const SizedBox(height: 10),
          if (status == PlaceVisitStatus.pending)
            AppButton(
              label: 'Skip',
              icon: Icons.skip_next,
              outlined: true,
              color: AppTheme.textSecondary,
              onPressed: () {
                ref
                    .read(travelCardControllerProvider.notifier)
                    .markSkipped(cardId, place.id);
                Navigator.pop(context);
              },
            ),
        ],
      );
}
