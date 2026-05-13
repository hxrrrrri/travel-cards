import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../../shared/models/travel_category.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../travel_cards/presentation/controllers/travel_card_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final cardState = ref.watch(travelCardControllerProvider);
    final name = auth.displayName ?? 'Explorer';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Dot texture
          const Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),
          // Ambient glow top-right
          Positioned(
            top: -80,
            right: -60,
            child: _AmbientGlow(color: AppTheme.primaryCyan.withOpacity(0.06), size: 300),
          ),
          // Ambient glow bottom-left
          Positioned(
            bottom: 100,
            left: -80,
            child: _AmbientGlow(color: const Color(0xFF7B52FF).withOpacity(0.06), size: 260),
          ),
          // Content
          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryCyan,
              backgroundColor: AppTheme.surfaceElevated,
              onRefresh: () =>
                  ref.read(travelCardControllerProvider.notifier).loadCards(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _Header(name: name, ref: ref)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _StatsRow(state: cardState),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'My Trips',
                          count: cardState.cards.length,
                        ),
                        const SizedBox(height: 14),
                        if (cardState.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: LoadingWidget(message: 'Loading trips…'),
                          )
                        else
                          _BentoGrid(cards: cardState.cards),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomNav(onAdd: () => context.go('/travel-cards/create')),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String name;
  final WidgetRef ref;
  const _Header({required this.name, required this.ref});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'TripGraph',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/auth');
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientTeal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      );
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TravelCardState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _MiniStat(
              label: 'Trips',
              value: '${state.cards.length}',
              gradient: AppTheme.gradientTeal),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Explored',
              value: '${state.totalDiscovered}',
              gradient: AppTheme.gradientPurple),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Visited',
              value: '${state.totalVisited}',
              gradient: AppTheme.gradientEmerald),
        ],
      );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Gradient gradient;
  const _MiniStat(
      {required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (count > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ),
        ],
      );
}

// ─── Bento grid ───────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  final List<TravelCardModel> cards;
  const _BentoGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return _EmptyBento(onTap: () => context.go('/travel-cards/create'));
    }

    // Build items: "New Trip" card first, then trip cards
    final items = <Widget>[
      _NewTripCard(onTap: () => context.go('/travel-cards/create')),
      ...cards.asMap().entries.map((e) => _TripBentoCard(
            card: e.value,
            gradientIndex: (e.key + 1),
          )),
    ];

    // Pair items into rows of 2
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final isLast = i + 1 >= items.length;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SizedBox(height: 160, child: items[i])),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                    height: 160, child: isLast ? const SizedBox() : items[i + 1]),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _NewTripCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewTripCard({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.primaryCyan.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add,
                    color: AppTheme.primaryCyan, size: 24),
              ),
              const SizedBox(height: 10),
              const Text('New Trip',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              const Text('Create card',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _TripBentoCard extends StatelessWidget {
  final TravelCardModel card;
  final int gradientIndex;
  const _TripBentoCard(
      {required this.card, required this.gradientIndex});

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.cardGradientAt(gradientIndex);
    final (statusLabel, statusAlpha) = switch (card.status) {
      TravelCardStatus.draft => ('Draft', 0.5),
      TravelCardStatus.active => ('Active', 1.0),
      TravelCardStatus.completed => ('Done', 0.8),
    };

    return GestureDetector(
      onTap: () => context.go('/travel-cards/${card.id}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: Colors.white.withOpacity(statusAlpha),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: Colors.white.withOpacity(0.5), size: 18),
              ],
            ),
            const Spacer(),
            // Category icons
            if (card.selectedCategories.isNotEmpty)
              Text(
                card.selectedCategories
                    .take(4)
                    .map((id) => TravelCategory.fromId(id).emoji)
                    .join(' '),
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 6),
            Text(
              card.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              card.discoveredCount > 0
                  ? '${card.visitedCount}/${card.discoveredCount} visited'
                  : _formatDate(card.updatedAt),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11),
            ),
            if (card.discoveredCount > 0 && card.visitedCount > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: card.visitedCount / card.discoveredCount,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _EmptyBento extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyBento({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.primaryCyan.withOpacity(0.2),
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientTeal,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Create your first trip',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Discover amazing places nearby',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final VoidCallback onAdd;
  const _BottomNav({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.fromLTRB(24, 14, 24, 28),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.95),
          border: const Border(
              top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(icon: Icons.home_rounded, active: true),
            _NavIcon(icon: Icons.explore_outlined),
            // Centre FAB
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientTeal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primaryCyan.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
            ),
            _NavIcon(icon: Icons.card_travel_outlined),
            _NavIcon(icon: Icons.person_outline),
          ],
        ),
      );
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  const _NavIcon({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) => Icon(
        icon,
        color: active ? AppTheme.primaryCyan : AppTheme.textSecondary,
        size: 26,
      );
}

// ─── Ambient glow ─────────────────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 0.8, spreadRadius: size * 0.3)],
        ),
      );
}
