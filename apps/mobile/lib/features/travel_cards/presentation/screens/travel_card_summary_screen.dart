import 'dart:ui';
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
      return const Scaffold(body: LoadingWidget(message: 'Loading trip…'));
    }
    if (card == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Trip Summary')),
        body: const EmptyStateWidget(
            title: 'Card not found',
            subtitle: 'This trip card may have been deleted.'),
      );
    }

    final gradientIdx = state.cards.indexOf(card);
    final cardGradient = AppTheme.cardGradientAt(gradientIdx + 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Dot texture
          const Positioned.fill(
              child: CustomPaint(painter: _DotPainter())),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    card: card,
                    gradient: cardGradient,
                    onBack: () => context.go('/dashboard'),
                    onDelete: () => _confirmDelete(context, ref, card),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _StatsRow(card: card),
                      const SizedBox(height: 24),
                      if (card.selectedCategories.isNotEmpty) ...[
                        _SectionLabel('Categories'),
                        const SizedBox(height: 10),
                        _CatChips(cats: card.selectedCategories),
                        const SizedBox(height: 24),
                      ],
                      if (card.originName != null) ...[
                        _LocationRow(card: card),
                        const SizedBox(height: 24),
                      ],
                      _ActionRow(card: card),
                      const SizedBox(height: 24),
                      if (card.discoveredPlaces.isNotEmpty) ...[
                        _SectionLabel('Places (${card.discoveredCount})'),
                        const SizedBox(height: 10),
                        ...card.discoveredPlaces.map((p) {
                          final status = card.placeStatuses[p.id] ??
                              PlaceVisitStatus.pending;
                          return _PlaceTile(
                            place: p,
                            status: status,
                            onVisited: () => ref
                                .read(travelCardControllerProvider.notifier)
                                .markVisited(card.id, p.id),
                          );
                        }),
                      ] else ...[
                        _EmptyPlaces(
                            onDiscover: () =>
                                context.go('/travel-cards/${card.id}/setup')),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext ctx, WidgetRef ref, TravelCardModel card) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Trip?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Delete "${card.title}"? This cannot be undone.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref
                  .read(travelCardControllerProvider.notifier)
                  .deleteCard(card.id);
              Navigator.pop(ctx);
              ctx.go('/dashboard');
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final TravelCardModel card;
  final Gradient gradient;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _HeroHeader(
      {required this.card,
      required this.gradient,
      required this.onBack,
      required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 180,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 15),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
            const Spacer(),
            _StatusPill(status: card.status),
            const SizedBox(height: 6),
            Text(
              card.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            if (card.description.isNotEmpty)
              Text(card.description,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _StatusPill extends StatelessWidget {
  final TravelCardStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TravelCardStatus.draft => 'Draft',
      TravelCardStatus.active => 'Active',
      TravelCardStatus.completed => 'Completed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TravelCardModel card;
  const _StatsRow({required this.card});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _StatCard(
              value: '${card.discoveredCount}',
              label: 'Discovered',
              gradient: AppTheme.gradientTeal),
          const SizedBox(width: 10),
          _StatCard(
              value: '${card.visitedCount}',
              label: 'Visited',
              gradient: AppTheme.gradientEmerald),
          const SizedBox(width: 10),
          _StatCard(
              value: '${card.pendingCount}',
              label: 'Pending',
              gradient: AppTheme.gradientAmber),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Gradient gradient;
  const _StatCard(
      {required this.value, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1)),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600));
}

// ─── Categories ───────────────────────────────────────────────────────────────

class _CatChips extends StatelessWidget {
  final List<String> cats;
  const _CatChips({required this.cats});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cats.map((id) {
          final cat = TravelCategory.fromId(id);
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text('${cat.emoji} ${cat.label}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          );
        }).toList(),
      );
}

// ─── Location ─────────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  final TravelCardModel card;
  const _LocationRow({required this.card});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientTeal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.originName!,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text(
                    '${(card.radiusMeters / 1000).toStringAsFixed(0)} km radius',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Action row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final TravelCardModel card;
  const _ActionRow({required this.card});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/travel-cards/${card.id}/map'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                    Icon(Icons.map, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Open Map',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.go('/travel-cards/${card.id}/setup'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore,
                        color: AppTheme.primaryCyan, size: 18),
                    SizedBox(width: 8),
                    Text('Rediscover',
                        style: TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

// ─── Place list ───────────────────────────────────────────────────────────────

class _PlaceTile extends StatelessWidget {
  final dynamic place;
  final PlaceVisitStatus status;
  final VoidCallback onVisited;
  const _PlaceTile(
      {required this.place, required this.status, required this.onVisited});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      PlaceVisitStatus.visited => (Icons.check_circle, AppTheme.success),
      PlaceVisitStatus.skipped =>
        (Icons.cancel_outlined, AppTheme.routeInactive),
      PlaceVisitStatus.pending =>
        (Icons.radio_button_unchecked, AppTheme.accentOrange),
    };
    final cat = TravelCategory.fromId(place.categoryId as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Text(cat.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name as String,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(
                  '${cat.label} · ⭐ ${(place.rating as double).toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: 18),
          if (status != PlaceVisitStatus.visited) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onVisited,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Icon(Icons.check,
                    color: AppTheme.success, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  final VoidCallback onDiscover;
  const _EmptyPlaces({required this.onDiscover});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryCyan.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.explore,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(height: 14),
            const Text('No places discovered yet',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Set a radius and categories to start',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            AppButton(
              label: 'Discover Places',
              icon: Icons.explore,
              onPressed: onDiscover,
            ),
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
