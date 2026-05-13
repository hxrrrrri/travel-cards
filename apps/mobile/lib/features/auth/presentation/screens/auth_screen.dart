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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildLogo(),
              const SizedBox(height: 48),
              Text(
                _isSignup ? 'Create Account' : 'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                _isSignup
                    ? 'Start discovering amazing places'
                    : 'Sign in to continue exploring',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_isSignup) ...[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Text(state.error!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: _isSignup ? 'Create Account' : 'Sign In',
                onPressed: _submit,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              AppButton(
                label: '⚡  Try Demo Mode',
                onPressed: () => ref.read(authControllerProvider.notifier).loginDemo(),
                isLoading: state.isLoading,
                outlined: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignup ? 'Already have an account? ' : "Don't have an account? ",
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSignup = !_isSignup),
                    child: Text(
                      _isSignup ? 'Sign In' : 'Sign Up',
                      style: const TextStyle(
                          color: AppTheme.primaryCyan, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, Color(0xFF0080FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Text(
            'TripGraph',
            style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ],
      );

  Widget _buildDivider() => Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: AppTheme.border)),
        ],
      );
}
