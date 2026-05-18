import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/part_image_placeholder.dart';
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
  Color get brandDark => neonDark.withValues(alpha: 0.3);
  Color get brandCard => const Color(0xFF161B1F);
  Color get brandWhite => Colors.white;
  Color get brandGray => const Color(0xFF90A4AE);
  Color get brandBorder => brandPrimary.withValues(alpha: 0.15);

  // Neon Shadows
  BoxShadow get neonBlueGlow => BoxShadow(
        color: neonBlue.withValues(alpha: 0.2),
        blurRadius: 20,
        spreadRadius: 2,
      );

  BoxShadow get neonGreenGlow => BoxShadow(
        color: neonGreen.withValues(alpha: 0.2),
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
                    loading: () => _buildLoadingShimmer(),
                    error: (err, stack) => _buildOfflineState(),
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
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 12),
          decoration: BoxDecoration(
            color: brandBlack.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: brandPrimary.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: brandPrimary.withValues(alpha: 0.12),
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
                width: isDesktop ? 48 : 36,
                height: isDesktop ? 48 : 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.bebasNeue(
                      fontSize: isDesktop ? 22 : 18, letterSpacing: 2, color: brandWhite),
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
              SizedBox(width: isDesktop ? 40 : 16),
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
      onPressed: () => context.go('/auth'),
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
      padding: EdgeInsets.fromLTRB(pad, isDesktop ? 180 : 120, pad, 100),
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
                      ..color = brandPrimary.withValues(alpha: 0.5),
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
              "We're a local bike repair shop Near Railway Station, Auto Market Rewari Haryana helping two-wheeler owners get back on the road — quickly, honestly, and without the runaround.",
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: GoogleFonts.barlow(
                  color: brandGray, fontSize: 18, height: 1.7),
            ),
          ),
          const SizedBox(height: 48),
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment:
                isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.center,
            children: [
              _buildPrimaryAction(context, isDesktop),
              SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 20),
              _buildSecondaryAction(() => _scrollTo(_howItWorksKey), true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [neonBlueGlow],
      ),
      child: ElevatedButton(
        onPressed: () => context.go('/auth'),
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: neonDark,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 44 : 32, 
            vertical: isDesktop ? 18 : 14
          ),
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
                  color: neonGreen.withValues(alpha: 0.05)),
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
      'NEAR RAILWAY STATION, AUTO MARKET REWARI HARYANA',
      'TRANSPARENT PRICING',
      'ALL BRANDS SERVICED',
      'CASH PAYMENT',
      'BOOK IN 60 SECONDS',
      'TWO-WHEELERS',
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
                                    color: brandBlack.withValues(alpha: 0.4))),
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
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: isDesktop ? 140 : 80),
      child: Column(
        children: [
          _sectionHeader(
              'Service Excellence',
              'OUR\nSERVICES',
              'From quick fixes to full servicing — we handle what your bike needs, when you need it.',
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
                        color: brandPrimary.withValues(alpha: 0.05),
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
                                        color: brandPrimary.withValues(alpha: 0.5),
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
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: isDesktop ? 140 : 80),
      color: brandDark,
      child: Column(
        children: [
          _sectionHeader(
              'Genuine Quality',
              'SPARE\nPARTS',
              'Quality parts for your bike — available at the shop or fitted during your service.',
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
                            : const PartImagePlaceholder(),
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
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: isDesktop ? 140 : 80),
      child: Column(
        children: [
          _sectionHeader(
              'Save More',
              'MEMBERSHIP\nPLANS',
              'Service your bike regularly and save more with every visit. Simple plans, no hidden terms.',
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
                                              color: neonBlue.withValues(alpha: 0.5),
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
                                                            .withValues(alpha: 0.7)
                                                        : brandGray))),
                                      ],
                                    ),
                                  ))
                              ,
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/auth'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.name.contains('Premium')
                                    ? neonDark
                                    : neonBlue,
                                foregroundColor: p.name.contains('Premium')
                                    ? brandWhite
                                    : neonDark,
                                padding:
                                    EdgeInsets.symmetric(vertical: isDesktop ? 18 : 14),
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
    return SizedBox(
      width: double.infinity,
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 3 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag.toUpperCase(),
                    style: GoogleFonts.barlowCondensed(
                        color: brandPrimary, 
                        fontSize: 14, 
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6)),
                const SizedBox(height: 20),
                Text(title,
                    style: GoogleFonts.bebasNeue(
                        fontSize: isDesktop ? 84 : 52,
                        height: 0.95,
                        letterSpacing: 2,
                        color: brandWhite)),
              ],
            ),
          ),
          if (isDesktop) const SizedBox(width: 60),
          Expanded(
            flex: isDesktop ? 2 : 0,
            child: Container(
              margin: EdgeInsets.only(top: isDesktop ? 0 : 32),
              child: Text(desc,
                  style: GoogleFonts.barlow(
                      color: brandGray, 
                      fontSize: 17, 
                      height: 1.7)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 80, horizontal: 40),
      child: Column(
        children: List.generate(3, (i) => 
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            height: 200,
            decoration: BoxDecoration(
              color: brandCard,
              border: Border.all(color: brandBorder),
            ),
            child: Shimmer.fromColors(
              baseColor: brandCard,
              highlightColor: 
                brandPrimary.withValues(alpha: 0.05),
              child: Container(color: brandCard),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 120, horizontal: 40),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -0.1, end: 0.1),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value,
                child: child,
              );
            },
            onEnd: () => setState(() {}),
            child: Icon(
              Icons.build_circle_outlined,
              size: 80,
              color: brandPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "WE'LL BE RIGHT BACK",
            style: GoogleFonts.bebasNeue(
              fontSize: 36,
              color: brandWhite,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Our systems are taking a quick break.\nCall us directly at +91 8168121711',
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              color: brandGray,
              fontSize: 16,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(
              landingDataProvider
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('TRY AGAIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: brandBlack,
              padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 14),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // --- How It Works ---
  Widget _buildHowItWorks(double pad, bool isDesktop, {Key? key}) {
    final steps = [
      {
        'num': '01',
        'title': 'Book Online',
        'desc':
            'Open the app, pick your service, choose a time. Done in under a minute.'
      },
      {
        'num': '02',
        'title': 'Drop or Visit',
        'desc':
            'Bring your bike to our shop Near Railway Station, Auto Market Rewari Haryana or call us to arrange pickup nearby.'
      },
      {
        'num': '03',
        'title': 'We Get to Work',
        'desc': 'Our mechanic inspects, confirms what needs fixing, and keeps you in the loop.'
      },
      {
        'num': '04',
        'title': 'Ride Away',
        'desc':
            'Pay cash when the job is done. No advance, no surprises.'
      },
    ];

    return Container(
      key: key,
      color: brandDark,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: isDesktop ? 140 : 80),
      child: Column(
        children: [
          _sectionHeader(
              'The Process',
              'HOW IT\nWORKS',
              'Getting your bike fixed has never been this simple.',
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
                        color: Colors.white.withValues(alpha: 0.05))),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'We\'re just getting started — but we mean business.',
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
          _featureRow('📍', 'Based in Rewari, Haryana',
              'We are a local shop — not a faceless platform. You know exactly where to find us.'),
          _featureRow('💬', 'Honest About What Needs Fixing',
              'We tell you what your bike needs and what it can wait on. No unnecessary upsells.'),
          _featureRow('💰', 'Pay Only When Done',
              'Cash payment after the job is complete. No advance payments, no hidden charges.'),
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
            color: brandPrimary.withValues(alpha: 0.1),
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
          Text('Book a service in under a minute. Pay cash when done.',
              style: GoogleFonts.barlow(color: brandGray, fontSize: 18)),
          const SizedBox(height: 52),
          Text('+91 8168121711',
              style: GoogleFonts.bebasNeue(
                  fontSize: isDesktop ? 64 : 42,
                  color: brandPrimary,
                  letterSpacing: 4)),
          const SizedBox(height: 40),
          _buildPrimaryAction(context, isDesktop),
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
                        'Your neighbourhood bike repair shop Near Railway Station, Auto Market Rewari Haryana.',
                        style: GoogleFonts.barlow(
                            color: brandGray, fontSize: 14, height: 1.8)),
                  ],
                ),
              ),
              if (isDesktop) const Spacer(),
              Wrap(
                spacing: isDesktop ? 80 : 40,
                runSpacing: 50,
                alignment: WrapAlignment.start,
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
                      '/privacy-policy',
                      '/terms-and-conditions',
                      '/refund-and-cancellation-policy',
                      '/shipping-and-delivery-policy',
                      '/payment-policy',
                      '/service-policy',
                    ],
                    isDesktop,
                  ),
                  _footerCol(
                      'Contact',
                      [
                        'repairmybike.in',
                        'support@repairmybike.in',
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
            mainAxisAlignment: isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.center,
            children: [
              Text('© 2026 RepairMyBike.in — All rights reserved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.barlow(color: brandGray, fontSize: 12)),
              const SizedBox(height: 20, width: 20),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _footerLink('Privacy Policy', '/privacy-policy', context),
                  _footerLink('Terms of Service', '/terms-and-conditions', context),
                  _footerLink('Refund Policy', '/refund-and-cancellation-policy', context),
                  _footerLink('Shipping Policy', '/shipping-and-delivery-policy', context),
                  _footerLink('Payment Policy', '/payment-policy', context),
                  _footerLink('Service Policy', '/service-policy', context),
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
              decorationColor: brandGray.withValues(alpha: 0.5))),
    );
  }

  Widget _footerCol(
      String title, List<String> links, List<String> routes, bool isDesktop) {
    return Container(
      constraints: BoxConstraints(minWidth: isDesktop ? 180 : 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.barlowCondensed(
                  color: brandPrimary, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3)),
          const SizedBox(height: 24),
          ...List.generate(links.length, (i) {
            final hasRoute = i < routes.length && routes[i].isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: hasRoute ? () => context.go(routes[i]) : null,
                hoverColor: Colors.transparent,
                child: Text(
                  links[i],
                  style: GoogleFonts.barlow(
                    color: const Color(0xFFB0BEC5),
                    fontSize: 14,
                    height: 1.4,
                    decoration: hasRoute ? TextDecoration.underline : null,
                    decorationColor: brandPrimary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
