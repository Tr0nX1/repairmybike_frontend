import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../data/content_api.dart';
import '../models/content.dart';

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

  // Constants for pure Neon look from landing page
  static const Color neonBlue = Color(0xFF01C9F5);
  static const Color neonGreen = Color(0xFF1BBE7B);
  static const Color neonDark = Color(0xFF0B0F12);
  static const Color brandCard = Color(0xFF161B1F);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final policy = await ContentApi().getPolicy(widget.slug);
      if (mounted) {
        setState(() {
          _policy = policy;
          _loading = false;
          if (policy == null) {
            _error = 'Policy content not found in backend.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error connecting to server. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neonDark,
      appBar: AppBar(
        backgroundColor: neonDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            letterSpacing: 2,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: neonBlue.withOpacity(0.1),
            height: 1,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: neonBlue))
          : _error != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: neonGreen),
            const SizedBox(height: 24),
            Text(
              'Opps!',
              style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: neonBlue,
                foregroundColor: neonDark,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with neon bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    neonBlue.withOpacity(0.05),
                    neonDark,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    width: 40,
                    height: 4,
                    color: neonBlue,
                    margin: const EdgeInsets.only(bottom: 16),
                   ),
                  Text(
                    _policy!.title.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 48,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: neonBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Last Updated: ${_policy!.updatedAt.toLocal().toString().split(' ')[0]}',
                        style: GoogleFonts.barlow(
                          color: neonBlue.withOpacity(0.6),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              child: MarkdownBody(
                data: _policy!.content,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.barlow(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.7),
                  h1: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 32, height: 2, letterSpacing: 1),
                  h2: GoogleFonts.bebasNeue(color: neonBlue, fontSize: 24, height: 2, letterSpacing: 1),
                  h3: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20, height: 2, letterSpacing: 1),
                  strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: neonBlue),
                  blockquote: const TextStyle(color: Colors.white70),
                  blockquoteDecoration: BoxDecoration(
                    color: brandCard,
                    border: const Border(left: BorderSide(color: neonBlue, width: 4)),
                  ),
                  tableHead: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 16),
                  tableBody: GoogleFonts.barlow(color: Colors.white70, fontSize: 14),
                  tableBorder: TableBorder.all(color: Colors.white12, width: 1),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(top: BorderSide(color: neonBlue.withOpacity(0.1), width: 1)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
