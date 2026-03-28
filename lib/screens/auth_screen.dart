import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../main_shell.dart';
import '../models/player_data.dart';
import '../services/guest_session.dart';
import '../services/local_storage_service.dart';
import 'onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool migrateFromGuest;
  const AuthScreen({super.key, this.migrateFromGuest = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _isLoading = false;
  String? _errorMsg;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

        if (widget.migrateFromGuest) {
          await gameService.migrateGuestToAccount();
        } else {
          await gameService.loadAll();
        }

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
          // Gemini Edit (2026-03-18): Added metadata to mark platform origin since Alex is unavailable
          data: {'origin_platform': 'flutter'},
        );

        if (widget.migrateFromGuest) {
          await gameService.migrateGuestToAccount();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        } else {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMsg = e.message);
    } catch (_) {
      setState(() => _errorMsg = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enterAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await GuestSession.start();

      // Create default guest player and save locally
      final wanderer = PlayerData(
        name: 'Wanderer',
        mainPath: 'Shadow Arts',
        sect: 'Unaffiliated',
        level: 1,
        qi: 0,
        spiritStones: 50,
        hp: 100,
        maxHp: 100,
      );

      await LocalStorageService.saveProfile(
        GuestSession.userId,
        wanderer,
        onboardingComplete: true,
      );

      // Load through GameService so all notifiers are populated
      await gameService.loadAll();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (_) {
      await GuestSession.clear();
      setState(() => _errorMsg = 'Failed to start guest session. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient Dark Ink to Deep Jade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B0F14), // Dark Ink
                  Color(0xFF0F3D3E), // Deep Jade Green
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.1, 1.0],
              ),
            ),
          ),
          
          // Subtle Particle Effects
          const Positioned.fill(child: _CultivationParticles()),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildFields(),
                  const SizedBox(height: 16),
                  if (_errorMsg != null) _buildError(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                  _buildToggle(),
                  if (!widget.migrateFromGuest) ...[
                    const SizedBox(height: 32),
                    _buildWandererButton(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Talisman/Pagoda Icon with Aura
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F3D3E).withValues(alpha: 0.4),
              border: Border.all(color: const Color(0xFF00D1B2).withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D1B2).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.gite_rounded, color: Color(0xFFD4AF37), size: 32),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sect Registry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSignIn
                ? 'Enter the path of cultivation'
                : 'Begin your journey into the Dao',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Spiritual Seal Divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Divider(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), endIndent: 12)),
              Icon(Icons.brightness_5_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.6), size: 16),
              Expanded(child: Divider(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), indent: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        _buildField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          label: 'Mortal Designation (Email)',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildField(
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          label: 'Secret Art (Password)',
          hint: '••••••••',
          obscure: true,
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isFocused = focusNode.hasFocus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        // Animated glow container
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D1B2).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onSubmitted: (_) => _submit(),
            cursorColor: const Color(0xFF00D1B2),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
              filled: true,
              fillColor: const Color(0xFF151A22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: const Color(0xFF8A94A6).withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: const Color(0xFF8A94A6).withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00D1B2), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Text(
        _errorMsg!,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF005A5B), Color(0xFF00D1B2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isLoading ? const Color(0xFF0F3D3E) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF00D1B2).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white70,
                  ),
                ),
              )
            : Text(
                _isSignIn ? 'OPEN IMMORTAL PORTAL' : 'FORGE DESTINY',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
      ),
    );
  }

  Widget _buildToggle() {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() {
          _isSignIn = !_isSignIn;
          _errorMsg = null;
        }),
        child: RichText(
          text: TextSpan(
            text: _isSignIn ? 'No sect affiliate? ' : 'Already have a legacy? ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            children: [
              TextSpan(
                text: _isSignIn ? 'Sign up' : 'Sign in',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWandererButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _enterAsGuest,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            'CONTINUE AS WANDERER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// Minimal floating particles to simulate "Qi"
class _CultivationParticles extends StatefulWidget {
  const _CultivationParticles();

  @override
  State<_CultivationParticles> createState() => _CultivationParticlesState();
}

class _CultivationParticlesState extends State<_CultivationParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Generate some random particles
    _particles = List.generate(15, (_) => _Particle(
      xOffset: _random.nextDouble(),
      yOffset: _random.nextDouble(),
      size: _random.nextDouble() * 4 + 2,
      speed: _random.nextDouble() * 0.5 + 0.1,
      sinOffset: _random.nextDouble() * math.pi * 2,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  final double xOffset;
  final double yOffset;
  final double size;
  final double speed;
  final double sinOffset;

  _Particle({
    required this.xOffset,
    required this.yOffset,
    required this.size,
    required this.speed,
    required this.sinOffset,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D1B2).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // Glow effect

    for (final p in particles) {
      // Move upwards and sway
      final dy = (p.yOffset - progress * p.speed) % 1.0;
      final actualY = dy < 0 ? dy + 1.0 : dy;
      
      final dx = p.xOffset + math.sin(progress * math.pi * 4 + p.sinOffset) * 0.05;
      
      final actualX = dx % 1.0;

      canvas.drawCircle(
        Offset(actualX * size.width, actualY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
