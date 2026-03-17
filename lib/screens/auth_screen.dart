import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../main_shell.dart';
import '../theme/night_guild_background.dart';
import 'onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _isLoading = false;
  String? _errorMsg;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Email and password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      if (_isSignIn) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        await gameService.loadAll();

        if (!mounted) return;
        final dest = playerNotifier.value.name.isEmpty
            ? const OnboardingScreen()
            : const MainShell();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dest),
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMsg = e.message);
    } catch (_) {
      setState(() => _errorMsg = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              _buildHeader(cs),
              const SizedBox(height: 48),
              _buildFields(cs),
              const SizedBox(height: 16),
              if (_errorMsg != null) _buildError(cs),
              const SizedBox(height: 24),
              _buildSubmitButton(cs),
              const SizedBox(height: 20),
              _buildToggle(cs),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withValues(alpha: 0.12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
          ),
          child: Icon(Icons.account_balance, color: cs.secondary, size: 22),
        ),
        const SizedBox(height: 16),
        Text(
          'Sect Registry',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isSignIn
              ? 'Sign in to continue your journey.'
              : 'Register to begin your journey.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFields(ColorScheme cs) {
    return Column(
      children: [
        _buildField(
          cs,
          controller: _emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildField(
          cs,
          controller: _passwordCtrl,
          label: 'Password',
          hint: '••••••••',
          obscure: true,
        ),
      ],
    );
  }

  Widget _buildField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: cs.onSurface.withValues(alpha: 0.25)),
            filled: true,
            fillColor: cs.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        _errorMsg!,
        style: const TextStyle(color: Colors.red, fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs) {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading
              ? cs.primary.withValues(alpha: 0.5)
              : cs.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              )
            : Text(
                _isSignIn ? 'SIGN IN' : 'CREATE ACCOUNT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildToggle(ColorScheme cs) {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() {
          _isSignIn = !_isSignIn;
          _errorMsg = null;
        }),
        child: Text(
          _isSignIn
              ? 'No account? Sign up'
              : 'Have an account? Sign in',
          style: TextStyle(
            color: cs.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
