import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'auth_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic responsive breakpoints
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    // Theme colors matching the app
    const bg = Color(0xFF0F0F0F);
    const accent = Color(0xFF01C9F5);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Navbar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.black.withOpacity(0.5), // Semi-transparent
              child: Row(
                children: [
                  // Logo / Brand Name
                  const Text(
                    'RepairMyBike',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Login Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthPage(toDetailsOnFinish: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),

            // --- Hero Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo/repairmybike_newlogo.jpeg'), // Use logo as placeholder or background
                  fit: BoxFit.cover,
                  opacity: 0.15, // Dim background
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg,
                    bg.withOpacity(0.8),
                    bg,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Premium Bike Care,\nDelivered to You.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 64 : 40,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Experience the ultimate convenience in bike servicing.\nProfessional mechanics, genuine parts, right at your doorstep.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                        // Same as login for now, or start flow
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthPage(toDetailsOnFinish: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text(
                      'Book a Service',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // --- Features Section ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _FeatureCard(
                      icon: Icons.timer_outlined,
                      title: 'Quick & Efficient',
                      desc: 'Most services completed within 60 minutes.',
                    ),
                    _FeatureCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Trusted Mechanics',
                      desc: 'Background verified and highly trained experts.',
                    ),
                    _FeatureCard(
                      icon: Icons.currency_rupee,
                      title: 'Transparent Pricing',
                      desc: 'Know exactly what you pay for. No hidden fees.',
                    ),
                  ],
                ),
              ),
            ),
            
            // --- Footer ---
            Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                color: const Color(0xFF050505),
                child: const Text(
                    '© 2024 RepairMyBike. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24),
                ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF01C9F5), size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    );
  }
}
