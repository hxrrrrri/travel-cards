import 'dart:ui';
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
  int _selectedPreset = -1;

  final _presets = [
    ('Weekend Getaway', '🌄', AppTheme.gradientTeal),
    ('Coorg Trip', '☕', AppTheme.gradientEmerald),
    ('Goa Beaches', '🏖️', AppTheme.gradientTeal),
    ('City Exploration', '🏙️', AppTheme.gradientPurple),
    ('Mountain Drive', '⛰️', AppTheme.gradientEmerald),
    ('Heritage Tour', '🏛️', AppTheme.gradientAmber),
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
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            // Dot texture
            Positioned.fill(
              child: CustomPaint(painter: _DotPainter()),
            ),
            // Glow
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primaryCyan.withOpacity(0.06),
                        blurRadius: 240,
                        spreadRadius: 80)
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(onBack: () => context.go('/dashboard')),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Name your\ntrip',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                                height: 1.1),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'A memorable name helps you find it later.',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 28),
                          _GlassField(
                            controller: _titleCtrl,
                            hint: 'e.g. Coorg Weekend',
                            label: 'Trip Name',
                            icon: Icons.card_travel_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          _GlassField(
                            controller: _descCtrl,
                            hint: 'Notes about this trip…',
                            label: 'Description (optional)',
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 28),
                          const Text('Quick Presets',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: _presets.length,
                            itemBuilder: (_, i) {
                              final (label, emoji, gradient) = _presets[i];
                              final isSelected = _selectedPreset == i;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPreset = i;
                                    _titleCtrl.text = label;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? gradient : null,
                                    color: isSelected
                                        ? null
                                        : AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : AppTheme.border),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(emoji,
                                          style: const TextStyle(
                                              fontSize: 22)),
                                      const SizedBox(height: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Create Trip Card',
                            icon: Icons.add_location_alt_outlined,
                            onPressed: _titleCtrl.text.trim().isEmpty
                                ? null
                                : _create,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.textPrimary, size: 16),
              ),
            ),
          ],
        ),
      );
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              labelText: label,
              prefixIcon: Icon(icon,
                  color: AppTheme.textSecondary, size: 20),
              filled: true,
              fillColor: AppTheme.surfaceElevated.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppTheme.primaryCyan, width: 1.5),
              ),
            ),
          ),
        ),
      );
}

class _DotPainter extends CustomPainter {
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
