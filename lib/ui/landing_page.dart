import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'vehicle_type_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    const bg = Color(0xFF0F0F0F);
    const card = Color(0xFF1C1C1C);
    const border = Color(0xFF2A2A2A);
    const accent = Color(0xFF01C9F5);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Navbar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: border, width: 1)),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.build_rounded, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'RepairMyBike',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),

            // --- Hero Section ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isDesktop ? 100 : 60,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bg,
                    const Color(0xFF0A1F23),
                    bg,
                  ],
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Text(
                      'Premium Bike Care,',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 72 : 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Delivered to Your Doorstep',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: isDesktop ? 72 : 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Professional mechanics • Genuine parts • Real-time tracking\nBook in 60 seconds, serviced in 60 minutes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isDesktop ? 20 : 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            elevation: 8,
                            shadowColor: accent.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Book a Service Now',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VehicleTypePage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          ),
                          child: const Text(
                            'Browse as Guest',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Services Section ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Text(
                      'Our Services',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 48 : 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Comprehensive bike care solutions for every need',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _ServiceCard(
                          icon: Icons.build_circle,
                          title: 'General Service',
                          description: 'Complete bike checkup and maintenance',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF01C9F5), Color(0xFF0088CC)],
                          ),
                        ),
                        _ServiceCard(
                          icon: Icons.oil_barrel,
                          title: 'Oil Change',
                          description: 'Premium engine oil replacement',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                          ),
                        ),
                        _ServiceCard(
                          icon: Icons.album,
                          title: 'Brake Service',
                          description: 'Brake pad & disc maintenance',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4ECDC4), Color(0xFF44A3A0)],
                          ),
                        ),
                        _ServiceCard(
                          icon: Icons.link,
                          title: 'Chain Lubrication',
                          description: 'Chain cleaning & lubrication',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA07A), Color(0xFFFF8C69)],
                          ),
                        ),
                        _ServiceCard(
                          icon: Icons.settings,
                          title: 'Wheel Alignment',
                          description: 'Precision wheel balancing',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                          ),
                        ),
                        _ServiceCard(
                          icon: Icons.electrical_services,
                          title: 'Electrical Service',
                          description: 'Complete electrical diagnostics',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- How It Works ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              color: const Color(0xFF0A0A0A),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Text(
                      'How It Works',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 48 : 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Wrap(
                      spacing: 40,
                      runSpacing: 40,
                      alignment: WrapAlignment.center,
                      children: [
                        _StepCard(
                          step: '1',
                          title: 'Book Online',
                          description: 'Choose your service and preferred time slot',
                          icon: Icons.phone_android,
                        ),
                        _StepCard(
                          step: '2',
                          title: 'We Come to You',
                          description: 'Our mechanic arrives at your location',
                          icon: Icons.location_on,
                        ),
                        _StepCard(
                          step: '3',
                          title: 'Expert Service',
                          description: 'Professional repair with genuine parts',
                          icon: Icons.construction,
                        ),
                        _StepCard(
                          step: '4',
                          title: 'Ride Safe',
                          description: 'Get back on the road in no time',
                          icon: Icons.check_circle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Why Choose Us ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Text(
                      'Why Choose RepairMyBike?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 48 : 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Wrap(
                      spacing: 32,
                      runSpacing: 32,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeatureCard(
                          icon: Icons.timer_outlined,
                          title: 'Lightning Fast',
                          desc: 'Most services completed within 60 minutes. No more waiting!',
                        ),
                        _FeatureCard(
                          icon: Icons.verified_user_outlined,
                          title: 'Certified Experts',
                          desc: 'Background verified mechanics with 5+ years experience.',
                        ),
                        _FeatureCard(
                          icon: Icons.currency_rupee,
                          title: 'Best Prices',
                          desc: 'Transparent pricing with no hidden costs. Pay what you see.',
                        ),
                        _FeatureCard(
                          icon: Icons.favorite_border,
                          title: '10K+ Happy Customers',
                          desc: 'Join thousands of satisfied riders across the city.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- CTA Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.1),
                    const Color(0xFF0A1F23),
                    accent.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Ready to Get Started?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Book your first service today and experience the difference',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Book Now - It\'s Free!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- Footer ---
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              color: const Color(0xFF050505),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.build_rounded, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RepairMyBike',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2024 RepairMyBike. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your trusted partner for bike care',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF01C9F5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF01C9F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black, size: 28),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF01C9F5), size: 40),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(color: Colors.white60, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
