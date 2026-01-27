import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/quick_service_api.dart';
import '../models/quick_service.dart';
import '../data/app_state.dart';

class QuickServiceDetailsPage extends StatefulWidget {
  const QuickServiceDetailsPage({super.key});

  @override
  State<QuickServiceDetailsPage> createState() => _QuickServiceDetailsPageState();
}

class _QuickServiceDetailsPageState extends State<QuickServiceDetailsPage> {
  QuickServiceConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final cfg = await QuickServiceApi().getConfig();
    if (mounted) {
      setState(() {
        _config = cfg;
        _loading = false;
      });
    }
  }

  Future<void> _initiateCall() async {
    if (_config == null) return;

    // 1. Create request record in backend first
    final phone = AppState.phoneNumber ?? '';
    await QuickServiceApi().createRequest(phone);

    // 2. Open dialer
    final uri = Uri.parse('tel:${_config!.supportPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Quick Service'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? const Center(child: Text('Service currently unavailable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary.withOpacity(0.2), cs.primary.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.flash_on, color: cs.primary, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Instant Mechanic Support',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Starting from ₹${_config!.basePrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'How it works',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Simple HTML preview or plain text for now
                      // In a real app we'd use flutter_widget_from_html
                      Text(
                        _config!.rulesHtml.replaceAll('<br>', '\n').replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: TextStyle(color: cs.onSurface.withOpacity(0.8), height: 1.5),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _initiateCall,
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Now for Quick Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Our team will guide you on the call',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
