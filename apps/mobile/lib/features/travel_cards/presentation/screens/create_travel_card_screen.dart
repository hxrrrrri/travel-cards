import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/travel_card_controller.dart';

class CreateTravelCardScreen extends ConsumerStatefulWidget {
  const CreateTravelCardScreen({super.key});

  @override
  ConsumerState<CreateTravelCardScreen> createState() =>
      _CreateTravelCardScreenState();
}

class _CreateTravelCardScreenState
    extends ConsumerState<CreateTravelCardScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  final _presets = [
    'Weekend Getaway',
    'Coorg Trip',
    'Goa Beaches',
    'City Exploration',
    'Mountain Drive',
    'Heritage Tour',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final card = await ref
        .read(travelCardControllerProvider.notifier)
        .createCard(_titleCtrl.text.trim(), _descCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (card != null) context.go('/travel-cards/${card.id}/setup');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('New Trip Card'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name your trip',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Give this travel card a memorable name',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Trip Name',
                  hintText: 'e.g. Coorg Weekend',
                  prefixIcon:
                      Icon(Icons.card_travel, color: AppTheme.textSecondary),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Notes about this trip...',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 24),
              Text('Quick Presets',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map((p) => GestureDetector(
                          onTap: () => setState(() => _titleCtrl.text = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _titleCtrl.text == p
                                    ? AppTheme.primaryCyan
                                    : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                color: _titleCtrl.text == p
                                    ? AppTheme.primaryCyan
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 40),
              AppButton(
                label: 'Create Trip Card',
                icon: Icons.add_location_alt_outlined,
                onPressed: _titleCtrl.text.trim().isEmpty ? null : _create,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      );
}
