import 'package:flutter/material.dart';
import '../../app/theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryCyan, strokeWidth: 2),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ],
        ),
      );
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.explore_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppTheme.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}
