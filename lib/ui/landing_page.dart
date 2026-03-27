import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/landing_provider.dart';
import '../models/service.dart';
import '../models/spare_part.dart';
import '../models/subscription.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Section Keys for scrolling
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _whyUsKey = GlobalKey();
  final GlobalKey _subscriptionsKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Constants for pure Neon look from main.dart
  static const Color neonBlue = Color(0xFF01C9F5);
  static const Color neonGreen = Color(0xFF1BBE7B);
  static const Color neonDark = Color(0xFF0B0F12);

  // Use current theme colors but overridden with consistent brand hexes
  Color get brandPrimary => neonBlue;
  Color get brandTertiary => neonGreen;
  Color get brandBlack => neonDark;
  Color get brandDark => neonDark.withOpacity(0.3);
  Color get brandCard => const Color(0xFF161B1F);
  Color get brandWhite => Colors.white;
  Color get brandGray => const Color(0xFF90A4AE);
  Color get brandBorder => brandPrimary.withOpacity(0.15);

  // Neon Shadows
  BoxShadow get neonBlueGlow => BoxShadow(
        color: neonBlue.withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: 2,
      );

  BoxShadow get neonGreenGlow => BoxShadow(
        color: neonGreen.withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: 2,
      );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final horizontalPad = isDesktop ? 60.0 : 24.0;

    final landingDataAsync = ref.watch(landingDataProvider);

    return Scaffold(
      backgroundColor: brandBlack,
      body: Stack(
        children: [
          SelectionArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHero(context, horizontalPad, isDesktop),
                  _buildTicker(),

                  // Real data integration
                  landingDataAsync.when(
                    data: (data) => Column(
                      children: [
                        _buildServices(horizontalPad, isDesktop, data.services,
                            key: _servicesKey),
                        _buildSpareParts(
                            horizontalPad, isDesktop, data.spareParts),
                        _buildSubscriptions(
                            horizontalPad, isDesktop, data.plans,
                            key: _subscriptionsKey),
                      ],
                    ),
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(80),
                      child: CircularProgressIndicator(),
                    )),
                    error: (err, stack) =>
                        Center(child: Text('Error loading data: $err')),
                  ),

                  _buildHowItWorks(horizontalPad, isDesktop,
                      key: _howItWorksKey),
                  _buildWhyUs(horizontalPad, isDesktop, key: _whyUsKey),
                  _buildCTA(horizontalPad, isDesktop),
                  _buildFooter(horizontalPad, isDesktop),
                ],
              ),
            ),
          ),

          // Floating Navbar
          _buildNavbar(context, horizontalPad, isDesktop),
        ],
      ),
    );
  }

  // --- Navbar ---
  Widget _buildNavbar(BuildContext context, double pad, bool isDesktop) {
    return Positioned(
      top: 30,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: brandBlack.withOpacity(0.85),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: brandPrimary.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: brandPrimary.withOpacity(0.12),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/launcher icon/transparent repairmybike launcher.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.bebasNeue(
                      fontSize: 22, letterSpacing: 2, color: brandWhite),
                  children: [
                    const TextSpan(text: 'REPAIR'),
                    const TextSpan(
                        text: 'MY', style: TextStyle(color: neonGreen)),
                    const TextSpan(text: 'BIKE'),
                  ],
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 60),
                _navItem('Services', () => _scrollTo(_servicesKey)),
                _navItem('Membership', () => _scrollTo(_subscriptionsKey)),
                _navItem('Workflow', () => _scrollTo(_howItWorksKey)),
                _navItem('About', () => _scrollTo(_whyUsKey)),
              ],
              const SizedBox(width: 40),
              _buildLoginBtn(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.barlowCondensed(
            color: brandGray,
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginBtn(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.push('/auth'),
      style: ElevatedButton.styleFrom(
        backgroundColor: brandPrimary,
        foregroundColor: brandBlack,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(),
        textStyle: GoogleFonts.barlowCondensed(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 2,
        ),
      ),
      child: const Text('LOGIN'),
    );
  }

  // --- Hero Section ---
  Widget _buildHero(BuildContext context, double pad, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, isDesktop ? 120 : 80, pad, 80),
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          RichText(
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.bebasNeue(
                  fontSize: isDesktop ? 120 : 64,
                  height: 0.9,
                  letterSpacing: 2,
                  color: brandWhite),
              children: [
                const TextSpan(text: 'YOUR BIKE\n'),
                // Outlined text simulation with neon glow
                TextSpan(
                  text: 'DESERVES',
                  style: TextStyle(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = isDesktop ? 2 : 1
                      ..color = brandPrimary.withOpacity(0.5),
                    shadows: [
                      Shadow(color: brandPrimary, blurRadius: 15),
                    ],
                  ),
                ),
                TextSpan(text: '\nTHE ', style: TextStyle(color: brandWhite)),
                TextSpan(
                    text: 'BEST.',
                    style: TextStyle(color: brandPrimary, shadows: [
                      Shadow(color: brandPrimary, blurRadius: 20)
                    ])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Expert mechanics. Genuine parts. Real-time tracking. Your motorcycle or scooter — serviced right where you are.',
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: GoogleFonts.barlow(
                  color: brandGray, fontSize: 18, height: 1.7),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment:
                isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              _buildPrimaryAction(context),
              const SizedBox(width: 24),
              _buildSecondaryAction(() => _scrollTo(_howItWorksKey), true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [neonBlueGlow],
      ),
      child: ElevatedButton(
        onPressed: () => context.push('/auth'),
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: neonDark,
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
          shape: const RoundedRectangleBorder(),
          textStyle: GoogleFonts.barlowCondensed(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 3,
          ),
        ),
        child: const Text('GET STARTED'),
      ),
    );
  }

  Widget _buildSecondaryAction(VoidCallback onTap, [bool showGlow = false]) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          boxShadow: [if (showGlow) neonGreenGlow],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: neonGreen),
                  color: neonGreen.withOpacity(0.05)),
              child: Icon(Icons.arrow_forward, size: 16, color: neonGreen),
            ),
            const SizedBox(width: 10),
            Text(
              'HOW IT WORKS',
              style: GoogleFonts.barlowCondensed(
                  color: neonGreen,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- Ticker ---
  Widget _buildTicker() {
    final items = [
      'DOORSTEP SERVICE',
      'GENUINE SPARE PARTS',
      'REAL-TIME TRACKING',
      'ALL BRANDS',
      'TRANSPARENT PRICING'
    ];
    return Container(
      color: brandPrimary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(10, (idx) {
            return Row(
              children: items
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          children: [
                            Text(
                              e,
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 18,
                                  letterSpacing: 3,
                                  color: brandBlack),
                            ),
                            const SizedBox(width: 40),
                            Text('●',
                                style: TextStyle(
                                    color: brandBlack.withOpacity(0.4))),
                          ],
                        ),
                      ))
                  .toList(),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildServices(double pad, bool isDesktop, List<Service> services,
      {Key? key}) {
    if (services.isEmpty) return const SizedBox.shrink();
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 120),
      child: Column(
        children: [
          _sectionHeader(
              'Service Excellence',
              'OUR\nSERVICES',
              'Expert repairs and maintenance carried out by certified professionals at your location.',
              isDesktop),
          const SizedBox(height: 70),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 1,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: isDesktop ? 0.8 : 1.2),
            itemBuilder: (context, i) {
              final s = services[i];
              return Container(
                decoration: BoxDecoration(
                  color: brandCard,
                  border: Border.all(color: brandBorder),
                  boxShadow: [
                    if (s.isFeatured)
                      BoxShadow(
                        color: brandPrimary.withOpacity(0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.images.isNotEmpty ? '🚀' : '🔧',
                        style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 20),
                    Text(s.name.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                            fontSize: 24,
                            letterSpacing: 1,
                            color: brandWhite,
                            shadows: s.isFeatured
                                ? [
                                    Shadow(
                                        color: brandPrimary.withOpacity(0.5),
                                        blurRadius: 10)
                                  ]
                                : [])),
                    const SizedBox(height: 12),
                    Text(s.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.barlow(
                            color: brandGray, fontSize: 13, height: 1.6)),
                    const Spacer(),
                    Text('FROM ₹${s.price} →',
                        style: GoogleFonts.barlowCondensed(
                            color: brandPrimary,
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpareParts(
      double pad, bool isDesktop, List<SparePartListItem> parts) {
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 120),
      color: brandDark,
      child: Column(
        children: [
          _sectionHeader(
              'Genuine Quality',
              'SPARE\nPARTS',
              'We use only authentic parts from top brands to ensure your bike performs at its peak.',
              isDesktop),
          const SizedBox(height: 70),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parts.length > 4 ? 4 : parts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 1,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.75),
            itemBuilder: (context, i) {
              final p = parts[i];
              return Container(
                color: brandBlack,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: brandCard,
                        child: p.thumbnail != null
                            ? Image.network(p.thumbnail!, fit: BoxFit.cover)
                            : Center(
                                child: Icon(Icons.settings,
                                    color: brandGray, size: 40)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.brandName.toUpperCase(),
                              style: GoogleFonts.barlowCondensed(
                                  color: brandPrimary,
                                  fontSize: 11,
                                  letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 20, color: brandWhite)),
                          const SizedBox(height: 12),
                          Text('₹${p.salePrice}',
                              style: GoogleFonts.barlow(
                                  color: brandWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptions(
      double pad, bool isDesktop, List<SubscriptionPlan> plans,
      {Key? key}) {
    if (plans.isEmpty) return const SizedBox.shrink();
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 120),
      child: Column(
        children: [
          _sectionHeader(
              'Ultimate Convenience',
              'MEMBERSHIP\nPLANS',
              'Enjoy priority service, zero labor charges, and expert care with our annual subscription plans.',
              isDesktop),
          const SizedBox(height: 70),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: plans
                .map((p) => Container(
                      width: isDesktop ? 350 : double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color:
                            p.name.contains('Premium') ? neonBlue : brandCard,
                        border: Border.all(
                            color: p.name.contains('Premium')
                                ? neonBlue
                                : brandBorder),
                        boxShadow: [
                          if (p.name.contains('Premium')) neonBlueGlow,
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name.toUpperCase(),
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 32,
                                  color: p.name.contains('Premium')
                                      ? neonDark
                                      : brandWhite)),
                          const SizedBox(height: 12),
                          Text('₹${p.price} / ${p.billingPeriod.toUpperCase()}',
                              style: GoogleFonts.barlowCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: p.name.contains('Premium')
                                      ? neonDark
                                      : neonBlue,
                                  shadows: p.name.contains('Premium')
                                      ? []
                                      : [
                                          Shadow(
                                              color: neonBlue.withOpacity(0.5),
                                              blurRadius: 10)
                                        ])),
                          const SizedBox(height: 32),
                          ...p.benefitsList
                              .map((benefit) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            size: 16,
                                            color: p.name.contains('Premium')
                                                ? neonDark
                                                : neonBlue),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Text(benefit.text,
                                                style: GoogleFonts.barlow(
                                                    fontSize: 14,
                                                    color: p.name
                                                            .contains('Premium')
                                                        ? neonDark
                                                            .withOpacity(0.7)
                                                        : brandGray))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/auth'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.name.contains('Premium')
                                    ? neonDark
                                    : neonBlue,
                                foregroundColor: p.name.contains('Premium')
                                    ? brandWhite
                                    : neonDark,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: const Text('GET STARTED'),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _sectionHeader(String tag, String title, String desc, bool isDesktop) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tag.toUpperCase(),
                style: GoogleFonts.barlowCondensed(
                    color: brandPrimary, fontSize: 12, letterSpacing: 5)),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.bebasNeue(
                    fontSize: isDesktop ? 72 : 48,
                    height: 1,
                    color: brandWhite)),
          ],
        ),
        if (isDesktop) const SizedBox(width: 40),
        Container(
          width: isDesktop ? 360 : double.infinity,
          margin: EdgeInsets.only(top: isDesktop ? 0 : 20),
          child: Text(desc,
              style: GoogleFonts.barlow(
                  color: brandGray, fontSize: 15, height: 1.8)),
        ),
      ],
    );
  }

  // --- How It Works ---
  Widget _buildHowItWorks(double pad, bool isDesktop, {Key? key}) {
    final steps = [
      {
        'num': '01',
        'title': 'Book Online',
        'desc':
            'Choose your service, pick a time slot, and confirm in under 2 minutes.'
      },
      {
        'num': '02',
        'title': 'Mechanic Arrives',
        'desc':
            'A certified mechanic reaches your doorstep with all tools and genuine parts.'
      },
      {
        'num': '03',
        'title': 'Live Tracking',
        'desc': 'Track the repair in real-time. Get notified at every step.'
      },
      {
        'num': '04',
        'title': 'Ride Away',
        'desc':
            'Pay only after you\'re satisfied. Get a digital service report and warranty.'
      },
    ];

    return Container(
      key: key,
      color: brandDark,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 120),
      child: Column(
        children: [
          _sectionHeader(
              'The Process',
              'HOW IT\nWORKS',
              'Four simple steps and your bike is as good as new — without leaving your home.',
              isDesktop),
          const SizedBox(height: 80),
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps
                .map((s) => Container(
                      width: isDesktop ? null : double.infinity,
                      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Text(s['num']!,
                                  style: GoogleFonts.bebasNeue(
                                      fontSize: isDesktop ? 100 : 80,
                                      color: brandBorder)),
                              Positioned(
                                top: isDesktop ? 60 : 50,
                                child: Text(s['title']!,
                                    style: GoogleFonts.bebasNeue(
                                        fontSize: 26,
                                        letterSpacing: 1,
                                        color: brandWhite)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(s['desc']!,
                              style: GoogleFonts.barlow(
                                  color: brandGray, fontSize: 14, height: 1.8)),
                        ],
                      ),
                    ))
                .toList()
                .map((w) => isDesktop ? Expanded(child: w) : w)
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- Why Us ---
  Widget _buildWhyUs(double pad, bool isDesktop, {Key? key}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 120),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        children: [
          Container(
            width: isDesktop ? null : double.infinity,
            height: isDesktop ? 500 : 300,
            decoration: BoxDecoration(
              color: brandCard,
              boxShadow: [neonBlueGlow],
            ),
            padding: const EdgeInsets.all(48),
            child: Stack(
              children: [
                Text('WHY',
                    style: GoogleFonts.bebasNeue(
                        fontSize: isDesktop ? 120 : 80,
                        color: Colors.white.withOpacity(0.05))),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'We don\'t just fix bikes.\nWe fix your peace of mind.',
                    style: GoogleFonts.barlow(
                        fontSize: isDesktop ? 24 : 18,
                        fontStyle: FontStyle.italic,
                        color: brandWhite),
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop)
            const SizedBox(width: 80)
          else
            const SizedBox(height: 60),
          _whyUsContent(isDesktop),
        ],
      ),
    );
  }

  Widget _whyUsContent(bool isDesktop) {
    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHY CHOOSE US',
              style: GoogleFonts.barlowCondensed(
                  color: brandPrimary, fontSize: 12, letterSpacing: 5)),
          Text('THE REPAIR\nDIFFERENCE',
              style: GoogleFonts.bebasNeue(
                  fontSize: isDesktop ? 52 : 42, color: brandWhite)),
          const SizedBox(height: 40),
          _featureRow('⚡', 'Doorstep Convenience',
              'No need to tow your bike. We come to your location at your preferred time.'),
          _featureRow('✅', 'Genuine Spare Parts',
              'We use only OEM-certified parts sourced directly from authorized suppliers.'),
          _featureRow('🛡️', 'Service Warranty',
              'Every repair comes with a warranty. If something goes wrong, we fix it free.'),
        ],
      ),
    );

    if (isDesktop) {
      return Expanded(child: content);
    }
    return content;
  }

  Widget _featureRow(String icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            color: brandPrimary.withOpacity(0.1),
            child: Center(child: Text(icon, style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.barlowCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brandWhite)),
                Text(desc,
                    style: GoogleFonts.barlow(color: brandGray, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CTA ---
  Widget _buildCTA(double pad, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 140),
      width: double.infinity,
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.bebasNeue(
                  fontSize: isDesktop ? 100 : 52,
                  height: 0.95,
                  color: brandWhite),
              children: [
                const TextSpan(text: 'READY TO\n'),
                TextSpan(
                  text: 'RIDE SMOOTH\n',
                  style: TextStyle(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = isDesktop ? 2 : 1
                        ..color = Colors.white30),
                ),
                const TextSpan(text: 'AGAIN?'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Book your doorstep service in less than 2 minutes.',
              style: GoogleFonts.barlow(color: brandGray, fontSize: 18)),
          const SizedBox(height: 52),
          Text('+91 8168121711',
              style: GoogleFonts.bebasNeue(
                  fontSize: isDesktop ? 64 : 42,
                  color: brandPrimary,
                  letterSpacing: 4)),
          const SizedBox(height: 40),
          _buildPrimaryAction(context),
        ],
      ),
    );
  }

  // --- Footer ---
  Widget _buildFooter(double pad, bool isDesktop) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 80),
          color: brandDark,
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isDesktop ? 300 : double.infinity,
                margin: EdgeInsets.only(bottom: isDesktop ? 0 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.bebasNeue(
                            fontSize: 32, letterSpacing: 3, color: brandWhite),
                        children: [
                          const TextSpan(text: 'REPAIR'),
                          TextSpan(
                              text: 'MY',
                              style: TextStyle(color: brandPrimary)),
                          const TextSpan(text: 'BIKE'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'India\'s most trusted doorstep motorcycle and scooter repair service.',
                        style: GoogleFonts.barlow(
                            color: brandGray, fontSize: 14, height: 1.8)),
                  ],
                ),
              ),
              if (isDesktop) const Spacer(),
              Wrap(
                spacing: 40,
                runSpacing: 40,
                children: [
                  _footerCol(
                      'Services',
                      [
                        'General Service',
                        'Engine Repair',
                        'Tyre & Brakes',
                        'AMC Plans'
                      ],
                      [],
                      isDesktop),
                  _footerCol(
                      'Company',
                      ['About Us', 'Careers', 'Partner With Us', 'Blog'],
                      [],
                      isDesktop),
                  _footerCol(
                    'Legal',
                    [
                      'Privacy Policy',
                      'Terms & Conditions',
                      'Refund Policy',
                      'Shipping Policy',
                      'Payment Policy',
                      'Service Policy',
                    ],
                    [
                      '/privacy',
                      '/terms',
                      '/refund',
                      '/shipping',
                      '/payment-policy',
                      '/service-policy',
                    ],
                    isDesktop,
                  ),
                  _footerCol(
                      'Contact',
                      [
                        'repairmybike.in',
                        'hello@repairmybike.in',
                        '+91 8168121711'
                      ],
                      [],
                      isDesktop),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: brandBorder))),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© 2026 RepairMyBike.in — All rights reserved.',
                  style: GoogleFonts.barlow(color: brandGray, fontSize: 12)),
              if (!isDesktop) const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _footerLink('Privacy Policy', '/privacy', context),
                  _footerLink('Terms of Service', '/terms', context),
                  _footerLink('Refund Policy', '/refund', context),
                  _footerLink('Payment Policy', '/payment-policy', context),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footerLink(String label, String route, BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.push(route),
      child: Text(label,
          style: GoogleFonts.barlow(
              color: brandGray,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: brandGray.withOpacity(0.5))),
    );
  }

  Widget _footerCol(
      String title, List<String> links, List<String> routes, bool isDesktop) {
    return Container(
      width: isDesktop ? 160 : 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.barlowCondensed(
                  color: brandGray, fontSize: 12, letterSpacing: 4)),
          const SizedBox(height: 20),
          ...List.generate(links.length, (i) {
            final hasRoute = i < routes.length && routes[i].isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: hasRoute
                  ? GestureDetector(
                      onTap: () => context.push(routes[i]),
                      child: Text(links[i],
                          style: TextStyle(
                              color: const Color(0xFF999999),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF555555))),
                    )
                  : Text(links[i],
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 14)),
            );
          }),
        ],
      ),
    );
  }
}
