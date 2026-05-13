import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../../shared/models/travel_category.dart';

class PlaceNodeMarker extends StatelessWidget {
  final PlaceModel place;
  final PlaceVisitStatus? status;
  final bool isSelected;
  final VoidCallback onTap;

  const PlaceNodeMarker({
    super.key,
    required this.place,
    required this.onTap,
    this.status,
    this.isSelected = false,
  });

  Color get _borderColor {
    if (isSelected) return AppTheme.accentOrange;
    return switch (status) {
      PlaceVisitStatus.visited => AppTheme.success,
      PlaceVisitStatus.skipped => AppTheme.routeInactive,
      _ => AppTheme.primaryCyan,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cat = TravelCategory.fromId(place.categoryId);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 58 : 50,
        height: isSelected ? 58 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface,
          border: Border.all(
            color: _borderColor,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _borderColor.withOpacity(0.4),
              blurRadius: isSelected ? 16 : 8,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cat.emoji, style: const TextStyle(fontSize: 18)),
            if (status == PlaceVisitStatus.visited)
              const Icon(Icons.check, color: AppTheme.success, size: 10),
          ],
        ),
      ),
    );
  }
}

class OriginMarker extends StatefulWidget {
  const OriginMarker({super.key});

  @override
  State<OriginMarker> createState() => _OriginMarkerState();
}

class _OriginMarkerState extends State<OriginMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background,
            border: Border.all(color: AppTheme.primaryCyan, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCyan.withOpacity(0.5 * _pulse.value),
                blurRadius: 20 * _pulse.value,
                spreadRadius: 4 * _pulse.value,
              ),
            ],
          ),
          child: const Icon(Icons.navigation,
              color: AppTheme.primaryCyan, size: 26),
        ),
      );
}
