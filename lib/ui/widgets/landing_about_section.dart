import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LandingAboutSection extends StatelessWidget {
  const LandingAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    const accent = Color(0xFF01C9F5);
    const textMuted = Colors.white60;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isDesktop ? 100 : 60,
      ),
      color: const Color(0xFF0F0F0F),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            // --- Header ---
            Column(
              children: [
                const Text(
                  'About RepairMyBike',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your trusted partner in bike care and maintenance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),

            // --- Story & Image ---
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStory(accent, textMuted)),
                      const SizedBox(width: 80),
                      Expanded(child: _buildFounderImage()),
                    ],
                  )
                : Column(
                    children: [
                      _buildFounderImage(),
                      const SizedBox(height: 40),
                      _buildStory(accent, textMuted),
                    ],
                  ),

            const SizedBox(height: 80),

            // --- Stats Grid ---
            Wrap(
              spacing: 40,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: const [
                _StatItem(
                  icon: Icons.people_outline,
                  value: '10,000+',
                  label: 'Happy Customers',
                ),
                _StatItem(
                  icon: Icons.construction_outlined,
                  value: '25,000+',
                  label: 'Repairs Completed',
                ),
                _StatItem(
                  icon: Icons.history_outlined,
                  value: '15+',
                  label: 'Years of Experience',
                ),
                _StatItem(
                  icon: Icons.verified_outlined,
                  value: '100%',
                  label: 'Reliability',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStory(Color accent, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Story',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _paragraph(
          'Founded in May 2025, RepairMyBike emerged from a father-son legacy of bike repair expertise. The story began with Rajesh Singh, a dedicated bike mechanic who built his reputation through decades of honest service and technical mastery. His passion for fixing bikes and helping people, even without a formal shop, laid the foundation for what would become RepairMyBike.',
          textMuted,
        ),
        _paragraph(
          'Following in his father\'s footsteps, Mohit Singh from Rewari, Haryana, understood the core values that made his father\'s work so impactful. Together with partners Mahir, Harish, and Vikash Bhatia, Mohit transformed his father\'s customer-first approach into RepairMyBike in 2025 - a service designed to eliminate all hassles associated with bike repairs.',
          textMuted,
        ),
        _paragraph(
          'Our mission reflects the values Rajesh Singh instilled: we aim to completely remove the stress and headache of bike repairs from our customers\' lives. Through our door-to-door pickup and drop service, expert mechanics, and home service options, we ensure you never have to worry about your bike\'s maintenance or repairs again.',
          textMuted,
        ),
        _paragraph(
          'At RepairMyBike, we\'ve modernized the traditional repair experience while maintaining the trust and personal touch that Rajesh Singh was known for. Just request a service, and let us handle everything else - that\'s our promise to you.',
          textMuted,
        ),
      ],
    );
  }

  Widget _paragraph(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFounderImage() {
    return Hero(
      tag: 'founder_image',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: 'https://res.cloudinary.com/dz81bjuea/image/upload/v1747031052/founder_vpnyov.jpg',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 400,
            color: const Color(0xFF1C1C1C),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF01C9F5))),
          ),
          errorWidget: (context, url, error) => Container(
            height: 400,
            color: const Color(0xFF1C1C1C),
            child: const Icon(Icons.person, color: Colors.white24, size: 80),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF01C9F5);
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
