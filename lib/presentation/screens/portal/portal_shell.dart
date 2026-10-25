import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../data/repositories/branding_repository.dart';
import '../../providers/branding_provider.dart';
import '../../providers/portal_provider.dart';
import 'landing_sections.dart';
import 'portal_chat_sheet.dart';
import 'portal_greeting.dart';

/// Frame shared by every public page: centred logo header, colour stripe, navigation, footer and the chat button.
/// [current] highlights the active link: home | about | officials | announcements | album | track | faqs | contact.
class PortalShell extends StatefulWidget {
  final String current;
  final Widget child;
  const PortalShell({super.key, required this.current, required this.child});

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh, so new announcements/FAQs show without restarting the app.
      if (mounted) context.read<PortalProvider>().load(force: true);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandingProvider>().info;
    final primary = brand.primary;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        tooltip: 'Ask the assistant',
        onPressed: () => showPortalChat(context, page: widget.current),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                _Banner(brand: brand),
                _NavBar(current: widget.current, primary: primary),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.5),
                  child: widget.child,
                ),
                SiteFooter(
                  brand: brand,
                  onTrack: () => context.go('/track'),
                  onFaqs: () => context.go('/faqs'),
                  onLogin: () => context.go('/login'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 84,
            bottom: 22,
            child: _ChatTeaser(
              key: ValueKey(widget.current),
              page: widget.current,
              barangay: brand.name,
              onOpen: () => showPortalChat(context, page: widget.current),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final BrandingInfo brand;
  const _Banner({required this.brand});

  @override
  Widget build(BuildContext context) {
    final primary = brand.primary;
    return Column(
      children: [
        InkWell(
          onTap: () => context.go('/welcome'),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppTheme.sunYellow.withValues(alpha: 0.55), width: 5),
                  ),
                  child: const ClipOval(child: BrandLogo(size: 56)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BaraTrack',
                        style: TextStyle(color: AppTheme.inkDark, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('${brand.name} · ${brand.city}'.toUpperCase(),
                        style: TextStyle(color: shadeColor(primary, -0.30), fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 5,
          child: Row(
            children: [
              AppTheme.burstBlue,
              AppTheme.burstTeal,
              AppTheme.burstOrange,
              primary,
              AppTheme.sunYellow,
              AppTheme.laurelGreen,
            ].map((c) => Expanded(child: Container(color: c))).toList(),
          ),
        ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  final String current;
  final Color primary;
  const _NavBar({required this.current, required this.primary});

  @override
  Widget build(BuildContext context) {
    Widget link(String label, String key, String route) {
      final active = current == key;
      return TextButton(
        onPressed: () => context.go(route),
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.white : const Color(0xFF3A2A2C),
          backgroundColor: active ? primary : null,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 4,
        children: [
          link('Home', 'home', '/welcome'),
          link('About', 'about', '/about'),
          link('Officials', 'officials', '/officials'),
          link('Announcements', 'announcements', '/announcements'),
          link('Album', 'album', '/album'),
          link('Track a Complaint', 'track', '/track'),
          link('FAQs', 'faqs', '/faqs'),
          link('Contact', 'contact', '/contact'),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: const Text('Resident Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Small greeting bubble next to the chat button. Appears once per visit, after a few seconds.
class _ChatTeaser extends StatefulWidget {
  final String page;
  final String barangay;
  final VoidCallback onOpen;
  const _ChatTeaser({super.key, required this.page, required this.barangay, required this.onOpen});

  static bool dismissed = false;

  @override
  State<_ChatTeaser> createState() => _ChatTeaserState();
}

class _ChatTeaserState extends State<_ChatTeaser> {
  bool _visible = false;
  Timer? _show;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    if (!_ChatTeaser.dismissed) {
      _show = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() => _visible = true);
        _hide = Timer(const Duration(seconds: 14), () {
          if (mounted) setState(() => _visible = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _show?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        offset: _visible ? Offset.zero : const Offset(-0.1, 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: _visible ? 1 : 0,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _ChatTeaser.dismissed = true;
                setState(() => _visible = false);
                widget.onOpen();
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width - 110).clamp(160.0, 270.0).toDouble()),
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: primary, width: 4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        PortalGreeting.teaser(widget.barangay, widget.page),
                        style: const TextStyle(color: Colors.black87, height: 1.35, fontSize: 13.5),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _ChatTeaser.dismissed = true;
                        setState(() => _visible = false);
                      },
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PortalTicker extends StatefulWidget {
  final List<String> items;
  final Color color;
  const PortalTicker({required this.items, required this.color});

  @override
  State<PortalTicker> createState() => PortalTickerState();
}

class PortalTickerState extends State<PortalTicker> {
  final _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (_controller.hasClients) _controller.jumpTo(_controller.offset + 1.4);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Container(
      height: 32,
      color: widget.color,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, i) {
          final text = items[i % items.length];
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppTheme.sunYellow, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Live date/time pill. Shown on the sign-in and registration screens.
class ClockChip extends StatefulWidget {
  final Color? background;
  const ClockChip({this.background});

  @override
  State<ClockChip> createState() => ClockChipState();
}

class ClockChipState extends State<ClockChip> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: widget.background, borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(DateFormat('EEE, MMM d · h:mm:ss a').format(_now),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

