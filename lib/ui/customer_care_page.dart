import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/content_api.dart';
import '../models/content.dart';

class CustomerCarePage extends StatefulWidget {
  const CustomerCarePage({super.key});

  @override
  State<CustomerCarePage> createState() => _CustomerCarePageState();
}

class _CustomerCarePageState extends State<CustomerCarePage> {
  List<SupportOption> _options = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final list = await ContentApi().getSupportOptions();
    if (mounted) {
      setState(() {
        _options = list;
        _loading = false;
      });
    }
  }

  Future<void> _handleTap(SupportOption option) async {
    String? url;
    switch (option.type) {
      case SupportType.call:
        url = 'tel:${option.value}';
        break;
      case SupportType.email:
        url = 'mailto:${option.value}';
        break;
      case SupportType.whatsapp:
         // Assuming value is phone number
        url = 'https://wa.me/${option.value.replaceAll(RegExp(r'\D'), '')}';
        break;
      case SupportType.website:
        url = option.value;
        if (!url.startsWith('http')) url = 'https://$url';
        break;
    }

    if (url != null) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch ${option.type.name}')),
          );
        }
      }
    }
  }

  Color _getHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF1E1E1E);
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF1E1E1E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Customer Care'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _options.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent, size: 64, color: cs.onSurface.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No support options available.',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final opt = _options[index];
                    final bgColor = _getHexColor(opt.bgColor);
                    
                    IconData iconData;
                    switch (opt.type) {
                      case SupportType.call: iconData = Icons.phone; break;
                      case SupportType.email: iconData = Icons.email; break;
                      case SupportType.whatsapp: iconData = Icons.message; break; // Use specific icon if available
                      case SupportType.website: iconData = Icons.language; break;
                    }

                    return InkWell(
                      onTap: () => _handleTap(opt),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.15), // Tinted background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: bgColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: bgColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: opt.iconImage != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: opt.iconImage!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Icon(iconData, color: bgColor),
                                      ),
                                    )
                                  : Icon(iconData, color: bgColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.title,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    opt.value,
                                    style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurface.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
