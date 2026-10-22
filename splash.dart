import 'package:flutter/material.dart';
import 'index.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IndexScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          // Background Backdrop matching light streetwear canvas
          Positioned.fill(
            child: Image.asset(
              'assets/Nike-Air-Jordans-Photoshop-mockup-template-2-1024x576 (1).jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF8F9FF)),
            ),
          ),

          // Clean Light Gradient Overlay for high readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xD9F8F9FF),
                    Color(0xF2F8F9FF),
                    Color(0xFFF8F9FF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Centered Brand Identity & Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container matching Index screen header
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0037B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0037B0).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/Logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.bolt_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Headline
                  RichText(
                    text: const TextSpan(
                      text: 'STEP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: Color(0xFF0B1C30),
                      ),
                      children: [
                        TextSpan(
                          text: 'UP',
                          style: TextStyle(color: Color(0xFF0037B0)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Capsule Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCE9FF)),
                    ),
                    child: const Text(
                      'FOREVER FASTER',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Color(0xFF0037B0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline with high-contrast text color
                  const Text(
                    'Curated heat for street & performance. Engineered for high-velocity agility and premium comfort.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF434655),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 44),

                  // Progress Indicator
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: Color(0xFF0037B0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}