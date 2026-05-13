import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isSignup = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final auth = ref.read(authControllerProvider.notifier);
    if (_isSignup) {
      auth.signup(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    } else {
      auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      if (next.isLoggedIn) context.go('/dashboard');
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Dot pattern
          const Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(),
            ),
          ),
          // Teal orb top-right
          Positioned(
            top: -100,
            right: -80,
            child: _GlowOrb(color: AppTheme.primaryCyan.withOpacity(0.12), size: 320),
          ),
          // Purple orb bottom-left
          Positioned(
            bottom: 80,
            left: -100,
            child: _GlowOrb(color: const Color(0xFF7B52FF).withOpacity(0.10), size: 280),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildTitle(),
                  const SizedBox(height: 32),
                  _buildForm(state),
                  const SizedBox(height: 20),
                  _buildDemoButton(state),
                  const SizedBox(height: 28),
                  _buildToggle(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() => Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppTheme.gradientTeal,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primaryCyan.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6))
              ],
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TripGraph',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              Text('Travel discovery',
                  style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      fontSize: 12)),
            ],
          ),
        ],
      );

  Widget _buildTitle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSignup ? 'Create\nAccount' : 'Welcome\nBack',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1.1),
          ),
          const SizedBox(height: 10),
          Text(
            _isSignup
                ? 'Start discovering amazing places around you'
                : 'Sign in to continue exploring the world',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
          ),
        ],
      );

  Widget _buildForm(AuthState state) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Column(
              children: [
                if (_isSignup) ...[
                  _Field(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                ],
                _Field(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _passCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(state.error!,
                              style: const TextStyle(
                                  color: AppTheme.danger, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: _isSignup ? 'Create Account' : 'Sign In',
                  onPressed: _submit,
                  isLoading: state.isLoading,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDemoButton(AuthState state) => Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Container(height: 0.5, color: AppTheme.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('or',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ),
              Expanded(
                  child: Container(height: 0.5, color: AppTheme.border)),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: state.isLoading
                ? null
                : () =>
                    ref.read(authControllerProvider.notifier).loginDemo(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primaryCyan.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradientTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Try Demo Mode',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('No API key',
                        style: TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildToggle() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isSignup ? 'Already have an account? ' : "Don't have an account? ",
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
          GestureDetector(
            onTap: () => setState(() => _isSignup = !_isSignup),
            child: Text(
              _isSignup ? 'Sign In' : 'Sign Up',
              style: const TextStyle(
                  color: AppTheme.primaryCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
        ],
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppTheme.background.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
          ),
        ),
      );
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color,
                blurRadius: size * 0.9,
                spreadRadius: size * 0.3)
          ],
        ),
      );
}

class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A2A);
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
