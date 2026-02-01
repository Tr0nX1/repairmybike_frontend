import 'package:flutter/material.dart';
import '../../data/contact_api.dart';

class LandingContactSection extends StatefulWidget {
  const LandingContactSection({super.key});

  @override
  State<LandingContactSection> createState() => _LandingContactSectionState();
}

class _LandingContactSectionState extends State<LandingContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  bool _showNotification = false;

  final _contactApi = ContactApi();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _contactApi.submitContactForm(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        message: _messageController.text,
      );

      if (!mounted) return;

      // Show notification
      setState(() {
        _showNotification = true;
        _isLoading = false;
      });

      // Hide after delay and reset form
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showNotification = false);
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _messageController.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    const accent = Color(0xFF01C9F5);
    const cardColor = Color(0xFF1C1C1C);

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isDesktop ? 100 : 60,
          ),
          color: const Color(0xFF0A0A0A),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  const Text(
                    'Contact Us',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get in touch with our expert team',
                    style: TextStyle(color: Colors.white60, fontSize: 18),
                  ),
                  const SizedBox(height: 80),
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildForm(accent, cardColor)),
                            const SizedBox(width: 48),
                            Expanded(child: _buildContactInfo(accent, cardColor)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildForm(accent, cardColor),
                            const SizedBox(height: 48),
                            _buildContactInfo(accent, cardColor),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
        
        // --- Success Notification ---
        if (_showNotification)
          Positioned(
            top: 100,
            left: 24,
            right: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * -50),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: const Border(left: BorderSide(color: Color(0xFFFF5733), width: 6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Thank you for your message!',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'You will get a response on your email soon.',
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm(Color accent, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send us a message',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildField(label: 'Name', controller: _nameController, icon: Icons.person_outline),
            const SizedBox(height: 20),
            _buildField(label: 'Email', controller: _emailController, icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildField(label: 'Phone', controller: _phoneController, icon: Icons.phone_android_outlined, keyboard: TextInputType.phone),
            const SizedBox(height: 20),
            _buildField(label: 'Message', controller: _messageController, icon: Icons.chat_bubble_outline, maxLines: 4),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text(
                        'Send Message',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: Colors.black26,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF01C9F5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return '$label is required';
            if (label == 'Email' && !val.contains('@')) return 'Enter a valid email';
            if (label == 'Message' && val.trim().length < 10) return 'Message too short';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfo(Color accent, Color cardColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _infoTile(Icons.phone_outlined, 'Phone', '+91 816-812-1711', accent),
              const SizedBox(height: 24),
              _infoTile(Icons.mail_outline, 'Email', 'support@repairmybike.in', accent),
              const SizedBox(height: 24),
              _infoTile(Icons.location_on_outlined, 'Address', 'Gali no.1 Shop no.1 Automarket, Rewari, Haryana', accent),
              const SizedBox(height: 24),
              _infoTile(Icons.access_time, 'Working Hours', 'Mon - Fri: 9 AM - 6 PM\nSat: 10 AM - 4 PM', accent),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency Service',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Need urgent bike repair? Our emergency team is available 24/7.',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Call Emergency Service', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
