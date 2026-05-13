import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../../shared/models/travel_category.dart';
import '../controllers/travel_card_controller.dart';

class TravelCardSummaryScreen extends ConsumerWidget {
  final String cardId;
  const TravelCardSummaryScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travelCardControllerProvider);
    final card = state.cards.where((c) => c.id == cardId).firstOrNull;

    if (state.isLoading && card == null) {
      return const Scaffold(body: LoadingWidget(message: 'Loading trip...'));
    }
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Summary')),
        body: const EmptyStateWidget(
            title: 'Card not found', subtitle: 'This trip card may have been deleted.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(card.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: () => _confirmDelete(context, ref, card),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/travel-cards/${card.id}/map'),
        icon: const Icon(Icons.map),
        label: const Text('Open Map'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBadge(status: card.status),
            const SizedBox(height: 16),
            if (card.originName != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryCyan, size: 16),
                  const SizedBox(width: 6),
                  Text(card.originName!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.radar, color: AppTheme.accentOrange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${(card.radiusMeters / 1000).toStringAsFixed(0)} km radius',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _StatGrid(card: card),
            const SizedBox(height: 24),
            if (card.selectedCategories.isNotEmpty) ...[
              Text('Categories', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: card.selectedCategories.map((id) {
                  final cat = TravelCategory.fromId(id);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text('${cat.emoji} ${cat.label}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (card.discoveredPlaces.isNotEmpty) ...[
              Text('Places', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...card.discoveredPlaces.map((p) {
                final status = card.placeStatuses[p.id] ?? PlaceVisitStatus.pending;
                return _PlaceListTile(
                  place: p,
                  status: status,
                  onVisited: () => ref
                      .read(travelCardControllerProvider.notifier)
                      .markVisited(card.id, p.id),
                  onSkipped: () => ref
                      .read(travelCardControllerProvider.notifier)
                      .markSkipped(card.id, p.id),
                );
              }),
            ] else ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Discover Places',
                icon: Icons.explore,
                onPressed: () => context.go('/travel-cards/${card.id}/setup'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext ctx, WidgetRef ref, TravelCardModel card) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Delete Trip?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Delete "${card.title}"? This cannot be undone.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(travelCardControllerProvider.notifier).deleteCard(card.id);
              Navigator.pop(ctx);
              ctx.go('/dashboard');
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TravelCardStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TravelCardStatus.draft => ('Draft', AppTheme.textSecondary),
      TravelCardStatus.active => ('Active', AppTheme.primaryCyan),
      TravelCardStatus.completed => ('Completed', AppTheme.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final TravelCardModel card;
  const _StatGrid({required this.card});

  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _StatCard(label: 'Discovered', value: '${card.discoveredCount}',
              color: AppTheme.primaryCyan, icon: Icons.place),
          _StatCard(label: 'Visited', value: '${card.visitedCount}',
              color: AppTheme.success, icon: Icons.check_circle_outline),
          _StatCard(label: 'Pending', value: '${card.pendingCount}',
              color: AppTheme.accentOrange, icon: Icons.schedule),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      );
}

class _PlaceListTile extends StatelessWidget {
  final dynamic place;
  final PlaceVisitStatus status;
  final VoidCallback onVisited;
  final VoidCallback onSkipped;

  const _PlaceListTile({
    required this.place,
    required this.status,
    required this.onVisited,
    required this.onSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      PlaceVisitStatus.visited => (Icons.check_circle, AppTheme.success),
      PlaceVisitStatus.skipped => (Icons.cancel_outlined, AppTheme.routeInactive),
      PlaceVisitStatus.pending => (Icons.radio_button_unchecked, AppTheme.accentOrange),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(
                  '${TravelCategory.fromId(place.categoryId).emoji}  ⭐ ${place.rating.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (status != PlaceVisitStatus.visited)
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.success, size: 20),
              onPressed: onVisited,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
