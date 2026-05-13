import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../shared/models/travel_card_model.dart';
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
      body: RefreshIndicator(
        color: AppTheme.primaryCyan,
        backgroundColor: AppTheme.surfaceElevated,
        onRefresh: () =>
            ref.read(travelCardControllerProvider.notifier).loadCards(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, ref, name),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _StatsRow(state: cardState),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'My Trips',
                    trailing: '${cardState.cards.length}',
                  ),
                  const SizedBox(height: 12),
                  if (cardState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: LoadingWidget(message: 'Loading trips...'),
                    )
                  else if (cardState.cards.isEmpty)
                    EmptyStateWidget(
                      title: 'No trips yet',
                      subtitle:
                          'Create your first trip card to start discovering amazing places.',
                      icon: Icons.map_outlined,
                      onAction: () => context.go('/travel-cards/create'),
                      actionLabel: 'Create Trip',
                    )
                  else
                    ...cardState.cards.map((c) => _TripCard(card: c)),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/travel-cards/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, WidgetRef ref, String name) =>
      SliverAppBar(
        pinned: true,
        expandedHeight: 120,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF111421), Color(0xFF0D1526)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name 👋',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'TripGraph',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                _LogoIcon(),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppTheme.textSecondary),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
            tooltip: 'Sign Out',
          ),
        ],
      );
}

class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryCyan, Color(0xFF0080FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.route, color: Colors.white, size: 24),
      );
}

class _StatsRow extends StatelessWidget {
  final TravelCardState state;

  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: _StatCard(
                  icon: Icons.card_travel,
                  label: 'Trips',
                  value: '${state.cards.length}',
                  color: AppTheme.primaryCyan)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  icon: Icons.explore,
                  label: 'Discovered',
                  value: '${state.totalDiscovered}',
                  color: const Color(0xFF6C63FF))),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  icon: Icons.check_circle,
                  label: 'Visited',
                  value: '${state.totalVisited}',
                  color: AppTheme.success)),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (trailing != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(trailing!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ),
          ],
        ],
      );
}

class _TripCard extends StatelessWidget {
  final TravelCardModel card;

  const _TripCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (card.status) {
      TravelCardStatus.draft => ('Draft', AppTheme.textSecondary),
      TravelCardStatus.active => ('Active', AppTheme.primaryCyan),
      TravelCardStatus.completed => ('Completed', AppTheme.success),
    };

    return GestureDetector(
      onTap: () => context.go('/travel-cards/${card.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (card.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(card.description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _Mini(Icons.place, '${card.discoveredCount}', AppTheme.primaryCyan),
                const SizedBox(width: 16),
                _Mini(Icons.check_circle_outline, '${card.visitedCount}', AppTheme.success),
                const SizedBox(width: 16),
                _Mini(Icons.schedule, '${card.pendingCount}', AppTheme.accentOrange),
                const Spacer(),
                Text(
                  _formatDate(card.updatedAt),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
            if (card.discoveredCount > 0 && card.visitedCount > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: card.visitedCount / card.discoveredCount,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.success),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _Mini(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );
}
