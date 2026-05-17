import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CmsPanelPage extends ConsumerStatefulWidget {
  const CmsPanelPage({super.key});

  @override
  ConsumerState<CmsPanelPage> createState() => _CmsPanelPageState();
}

class _CmsPanelPageState extends ConsumerState<CmsPanelPage> {

  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  bool _isBroadcasting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management (CMS)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Home Banners'),
            _buildBannerManager(),
            const SizedBox(height: 32),
            _buildSectionTitle('Notification Broadcaster'),
            _buildNotificationForm(),
            const SizedBox(height: 32),
            _buildSectionTitle('Legal Policies'),
            _buildPolicyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBannerManager() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text('Active Banners'),
            subtitle: Text('Manage homepage promotional sliders'),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/400x200'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 14, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add New Banner'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _notifTitleController,
              decoration: const InputDecoration(
                labelText: 'Campaign Title',
                hintText: 'e.g. Weekend Special Offer!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notifBodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                hintText: 'Get 20% off on all oil changes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBroadcasting ? null : _handleBroadcast,
                icon: const Icon(Icons.send),
                label: Text(_isBroadcasting ? 'Sending...' : 'Broadcast to All Users'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyList() {
    final policies = ['Terms & Conditions', 'Privacy Policy', 'Refund Policy', 'Service Policy'];
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: policies.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          title: Text(policies[index]),
          trailing: const Icon(Icons.edit_note),
          onTap: () {},
        ),
      ),
    );
  }

  Future<void> _handleBroadcast() async {
    if (_notifTitleController.text.isEmpty || _notifBodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and body')),
      );
      return;
    }

    setState(() => _isBroadcasting = true);
    try {
      // Mock API call
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification broadcasted successfully!')),
        );
        _notifTitleController.clear();
        _notifBodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Broadcast failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBroadcasting = false);
    }
  }
}
