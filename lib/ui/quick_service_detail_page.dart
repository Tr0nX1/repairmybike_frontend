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

  Future<void> _showQuickServiceForm() async {
    if (_config == null) return;

    final nameController = TextEditingController(text: AppState.fullName ?? '');
    final phoneController = TextEditingController(text: AppState.phoneNumber ?? '');
    final numberController = TextEditingController();
    final manufacturerController = TextEditingController(text: AppState.vehicleBrand ?? '');
    final modelController = TextEditingController(text: AppState.vehicleName ?? '');

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        bool submitting = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.flash_on, color: cs.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Service Request',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide details so our mechanic can assist you faster.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name (Required)
                        TextFormField(
                          controller: nameController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Your Name *',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone Number (Required)
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Vehicle Number (Optional)
                        TextFormField(
                          controller: numberController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Vehicle Number (Optional)',
                            hintText: 'e.g. HR-26-AB-1234',
                            prefixIcon: const Icon(Icons.pin),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Manufacturer & Model
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: manufacturerController,
                                style: TextStyle(color: cs.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Manufacturer',
                                  hintText: 'e.g. Honda',
                                  prefixIcon: const Icon(Icons.two_wheeler),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: modelController,
                                style: TextStyle(color: cs.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Model',
                                  hintText: 'e.g. Activa 6G',
                                  prefixIcon: const Icon(Icons.directions_bike),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() => submitting = true);

                                    final name = nameController.text.trim();
                                    final phone = phoneController.text.trim();
                                    final vehicleNum = numberController.text.trim();
                                    final manufacturer = manufacturerController.text.trim();
                                    final model = modelController.text.trim();

                                    final req = await QuickServiceApi().createRequest(
                                      phoneNumber: phone,
                                      name: name,
                                      vehicleNumber: vehicleNum,
                                      vehicleManufacturer: manufacturer,
                                      vehicleModel: model,
                                    );

                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }

                                    if (req == null && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Failed to submit request. Please check phone number.')),
                                      );
                                      return;
                                    }

                                    // Launch phone dialer
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
                                  },
                            icon: submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.phone_in_talk),
                            label: Text(
                              submitting ? 'Submitting...' : 'Submit & Call Now',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                            colors: [cs.primary.withValues(alpha: 0.2), cs.primary.withValues(alpha: 0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
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
                      Text(
                        _config!.rulesHtml.replaceAll('<br>', '\n').replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8), height: 1.5),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _showQuickServiceForm,
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
