import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_page.dart';
import 'vehicle_type_page.dart';
import 'widgets/landing_sections.dart';
import 'widgets/landing_about_section.dart';
import 'widgets/landing_contact_section.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final _servicesKey = GlobalKey();
  final _partsKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _contactKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    const bg = Color(0xFF0F0F0F);
    const border = Color(0xFF2A2A2A);
    const accent = Color(0xFF01C9F5);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // --- Main Scrollable Content ---
          SingleChildScrollView(
            child: Column(
              children: [
                // Top spacing for sticky header
                const SizedBox(height: 80),

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
                                    builder: (_) => const AuthPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                elevation: 8,
                                shadowColor: accent.withValues(alpha: 0.5),
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

                // --- Services Section (Dynamic) ---
                Container(key: _servicesKey, child: const LandingServicesSection()),

                // --- Spare Parts Section (Dynamic) ---
                Container(key: _partsKey, child: const LandingSparePartsSection()),

                // --- About Us Section ---
                Container(key: _aboutKey, child: const LandingAboutSection()),

                // --- How It Works ---
                Container(
                  key: _howItWorksKey,
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

                // --- Contact Section ---
                Container(key: _contactKey, child: const LandingContactSection()),

                // --- CTA Section ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.1),
                        const Color(0xFF0A1F23),
                        accent.withValues(alpha: 0.1),
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
                              builder: (_) => const AuthPage(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  width: double.infinity,
                  color: const Color(0xFF050505),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildBrandCol(accent)),
                              const SizedBox(width: 48),
                              Expanded(child: _buildFooterCol('Quick Links', ['Services', 'Spare Parts', 'How It Works', 'About Us'])),
                              const SizedBox(width: 24),
                              Expanded(child: _buildFooterCol('Support', ['Help Center', 'Safety', 'Terms of Service', 'Privacy Policy'])),
                              const SizedBox(width: 24),
                              Expanded(child: _buildConnectCol(accent)),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildBrandCol(accent),
                              const SizedBox(height: 48),
                              _buildFooterCol('Quick Links', ['Services', 'Spare Parts', 'How It Works', 'About Us']),
                              const SizedBox(height: 32),
                              _buildFooterCol('Support', ['Help Center', 'Safety', 'Terms of Service', 'Privacy Policy']),
                              const SizedBox(height: 32),
                              _buildConnectCol(accent),
                            ],
                          ),
                        const SizedBox(height: 80),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 32),
                        const Text(
                          '© 2024 RepairMyBike. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white24, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Sticky Sticky Header (Fixed) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    border: Border(bottom: BorderSide(color: border, width: 1)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Row(
                        children: [
                          // --- Logo & Brand ---
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/logo/repairmybike_newlogo.jpeg',
                                  height: 44,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'RepairMyBike',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // --- Navigation Links (Desktop) ---
                          if (isDesktop)
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: Row(
                                children: [
                                  _navLink('Services', _servicesKey),
                                  const SizedBox(width: 24),
                                  _navLink('Parts', _partsKey),
                                  const SizedBox(width: 24),
                                  _navLink('How It Works', _howItWorksKey),
                                  const SizedBox(width: 24),
                                  _navLink('About', _aboutKey),
                                ],
                              ),
                            ),
                          // --- Login Button ---
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label, GlobalKey key) {
    return InkWell(
      onTap: () => _scrollTo(key),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildBrandCol(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo/repairmybike_newlogo.jpeg',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'RepairMyBike',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Revolutionizing bike care with doorstep service, expert mechanics, and genuine spare parts. Your ride, our responsibility.',
          style: TextStyle(color: Colors.white24, fontSize: 15, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildFooterCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (link == 'Services') _scrollTo(_servicesKey);
                  if (link == 'Spare Parts') _scrollTo(_partsKey);
                  if (link == 'About Us') _scrollTo(_aboutKey);
                  if (link == 'How It Works') _scrollTo(_howItWorksKey);
                  if (link == 'Help Center') _scrollTo(_contactKey);
                },
                child: Text(
                  link,
                  style: const TextStyle(color: Colors.white24, fontSize: 15),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildConnectCol(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect With Us',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _socialIcon(Icons.facebook, accent),
            const SizedBox(width: 16),
            _socialIcon(Icons.camera_alt, accent),
            const SizedBox(width: 16),
            _socialIcon(Icons.alternate_email, accent),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => _scrollTo(_contactKey),
          child: const Text(
            'Helpline: +91 816-812-1711',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color accent) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
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
                  color: const Color(0xFF01C9F5).withValues(alpha: 0.1),
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
