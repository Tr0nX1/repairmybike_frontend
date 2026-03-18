import 'package:flutter/material.dart';
import '../data/content_api.dart';
import '../models/content.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PolicyPage extends StatefulWidget {
  final String slug;
  final String title;

  const PolicyPage({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  Policy? _policy;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final policy = await ContentApi().getPolicy(widget.slug);
    if (mounted) {
      setState(() {
        _policy = policy;
        _loading = false;
        if (policy == null) {
          _error = 'Failed to load policy. Please try again later.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: cs.error),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _load();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _policy!.title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${_policy!.updatedAt.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const Divider(height: 32),
                      MarkdownBody(
                        data: _policy!.content,
                        styleConfig: MarkdownStyleConfig(
                          p: TextStyle(color: cs.onSurface, height: 1.5),
                          h1: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                          h2: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                          h3: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// Simple internal helper since we might not have flutter_markdown yet or a custom config
class MarkdownStyleConfig {
  final TextStyle? p;
  final TextStyle? h1;
  final TextStyle? h2;
  final TextStyle? h3;

  MarkdownStyleConfig({this.p, this.h1, this.h2, this.h3});
}
