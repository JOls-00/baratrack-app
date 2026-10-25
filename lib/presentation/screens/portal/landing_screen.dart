import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../data/repositories/branding_repository.dart';
import '../../providers/branding_provider.dart';
import 'landing_sections.dart';
import 'portal_shell.dart';
import 'track_panel.dart';

const _maxW = 1100.0;

/// Home page of the public portal. Layout: hero + tracker, services, bento highlights,
/// dark steps band, community (vision/mission), officials, history and a closing call to action.
/// All colours come from the admin-chosen theme colour.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<BrandingProvider>();
    return PortalShell(
      current: 'home',
      child: Column(
        children: [
          _Hero(brand: b.info),
          const _Features(),
          const _WhyBento(),
          const _StepsBand(),
          _Community(brand: b.info, officialsCount: b.officials.length),
          OfficialsSection(officials: b.officials, background: Color.alphaBlend(b.info.primary.withValues(alpha: 0.05), Colors.white)),
          AlbumSection(brand: b.info, limit: 6),
          HistorySection(brand: b.info),
          const _CtaCard(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------
Widget _page(Widget child, {Color? bg, double v = 56}) => Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: v),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _maxW), child: child)),
    );

BoxDecoration _cardDeco(Color primary, {Color? color, double radius = 24, bool shadow = true}) => BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: primary.withValues(alpha: 0.08)),
      boxShadow: shadow
          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 10))]
          : null,
    );

class _Heading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final bool center;
  final Color? color;
  const _Heading(this.eyebrow, this.title, {this.center = true, this.color});

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(),
            style: TextStyle(
                color: color == null ? primary : AppTheme.sunYellow, fontSize: 12, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
                color: color ?? AppTheme.inkDark, fontSize: 32, height: 1.15, letterSpacing: -0.6, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  final BrandingInfo brand;
  const _Hero({required this.brand});

  @override
  Widget build(BuildContext context) {
    final primary = brand.primary;
    final wide = MediaQuery.of(context).size.width > 1000;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(primary.withValues(alpha: 0.13), Colors.white),
            Color.alphaBlend(AppTheme.sunYellow.withValues(alpha: 0.20), Colors.white),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotsPainter(primary.withValues(alpha: 0.22)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 110),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const TrackPanel(),
                        if (wide) ...[
                          Positioned(left: -64, top: -14, child: _Tile(Icons.description_outlined, primary)),
                          Positioned(right: -64, top: -14, child: _Tile(Icons.search, primary)),
                          Positioned(right: -56, bottom: -24, child: _Tile(Icons.event_available_outlined, primary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                      child: Text('MALIGAYANG PAGDATING',
                          style: TextStyle(color: primary, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    const Text('File your complaint. Follow every step.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppTheme.inkDark)),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(
                        'Isumbong online, i-track gamit ang reference number, at alamin ang petsa ng hearing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade700),
                      ),
                    ),
                    if (brand.slogan.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('\u201C${brand.slogan.trim()}\u201D',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic, color: shadeColor(primary, -0.2))),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: -1, height: 60, child: CustomPaint(painter: _WavePainter(Colors.white))),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Tile(this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Icon(icon, color: color),
      );
}

class _DotsPainter extends CustomPainter {
  final Color color;
  const _DotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = 11.0; y < size.height; y += 22) {
      for (var x = 11.0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1.4, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
}

class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.5)
      ..cubicTo(w * 0.172, h * 1.167, w * 0.328, 0, w * 0.5, h * 0.467)
      ..cubicTo(w * 0.672, h * 0.933, w * 0.828, h * 1.033, w, h * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.color != color;
}

/// Illustration only: a sample of what the tracker shows (not real data).

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Services card
// ---------------------------------------------------------------------------
class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final items = [
      (Icons.edit_note, 'File online', 'Ilahad ang detalye ng reklamo kahit anong oras, mula sa phone o computer.'),
      (Icons.attach_file, 'Attach evidence', 'Magdagdag ng larawan o dokumento bilang ebidensya sa iyong reklamo.'),
      (Icons.event_available_outlined, 'Status and hearing dates', 'Alamin ang kasalukuyang status at ang petsa ng hearing gamit ang reference number.'),
    ];
    return _page(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDeco(primary),
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 760;
          final title = const _Heading('Mga serbisyo', 'Serbisyong abot-kamay,\nanumang oras.', center: false);
          final desc = Text(
            'Dinisenyo ang portal para madali sa bawat residente: mag-file, mag-attach ng ebidensya, at sumubaybay nang hindi na kailangang magtanong sa barangay hall para lang sa update.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          );
          final cols = wide ? 3 : 1;
          final w = (c.maxWidth - 24 * (cols - 1)) / cols;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(flex: 5, child: title),
                    const SizedBox(width: 40),
                    Expanded(flex: 4, child: desc),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 14), desc]),
            const SizedBox(height: 26),
            Divider(color: primary.withValues(alpha: 0.12)),
            const SizedBox(height: 22),
            Wrap(spacing: 24, runSpacing: 22, children: [
              for (final f in items)
                SizedBox(
                  width: w,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(f.$1, color: primary, size: 28),
                    const SizedBox(height: 10),
                    Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(f.$3, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
                  ]),
                ),
            ]),
          ]);
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bento highlights
// ---------------------------------------------------------------------------
class _WhyBento extends StatelessWidget {
  const _WhyBento();

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final dark = shadeColor(primary, -0.34);

    Widget tile(Widget child) => Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(24)),
          child: child,
        );

    final big = tile(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('24/7', style: TextStyle(fontSize: 64, height: 1, fontWeight: FontWeight.w800, color: primary, letterSpacing: -2)),
      const SizedBox(height: 10),
      const Text('Online filing at any hour, kahit nasa labas ka ng barangay hall.', style: TextStyle(fontSize: 16, height: 1.4)),
    ]));

    final instant = tile(Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Check your case status instantly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 8),
          Text('Ilagay ang reference number at apelyido. Hindi mo kailangang mag-login.', style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
        ]),
      ),
      const SizedBox(width: 16),
      InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go('/track'),
        child: CircleAvatar(radius: 26, backgroundColor: dark, child: const Icon(Icons.search, color: Colors.white)),
      ),
    ]));

    final stages = ['Filed', 'Review', 'Hearing', 'Resolved'];
    final progress = tile(LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 560;
      final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Clear case progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Bawat yugto ng iyong reklamo ay makikita mo, mula pagsumite hanggang sa resolusyon.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
      ]);
      final bars = Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDeco(primary, radius: 18),
        child: Row(children: [
          for (var i = 0; i < stages.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == stages.length - 1 ? 0 : 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 8, decoration: BoxDecoration(color: i < 3 ? primary : primary.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Text(stages[i], style: const TextStyle(fontSize: 12)),
                ]),
              ),
            ),
        ]),
      );
      return wide
          ? Row(children: [Expanded(child: text), const SizedBox(width: 24), Expanded(child: bars)])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 18), bars]);
    }));

    return _page(
      Column(children: [
        const _Heading('Bakit BaraTrack', 'Why residents prefer BaraTrack'),
        const SizedBox(height: 30),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 760;
          return Column(children: [
            wide
                ? IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(flex: 4, child: big),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: instant),
                    ]),
                  )
                : Column(children: [big, const SizedBox(height: 16), instant]),
            const SizedBox(height: 16),
            progress,
          ]);
        }),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Dark steps band
// ---------------------------------------------------------------------------
class _StepsBand extends StatelessWidget {
  const _StepsBand();

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final steps = [
      ('Create an account', 'Mag-register gamit ang iyong email at i-verify ito gamit ang code.'),
      ('File your complaint', 'Ilahad ang detalye at magdagdag ng ebidensya, online at kahit anong oras.'),
      ('Track the progress', 'Alamin ang status at petsa ng hearing gamit ang iyong reference number.'),
    ];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.3, 0.7, 1],
          colors: [
            Colors.white,
            Color.alphaBlend(primary.withValues(alpha: 0.11), Colors.white),
            Color.alphaBlend(AppTheme.sunYellow.withValues(alpha: 0.20), Colors.white),
            Colors.white,
          ],
        ),
      ),
      child: _page(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Heading('Paano gumagana', 'Tatlong hakbang para sa\nmabilis na serbisyo.', center: false),
          const SizedBox(height: 30),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 720 ? 3 : 1;
            final w = (c.maxWidth - 16 * (cols - 1)) / cols;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              for (var i = 0; i < steps.length; i++)
                SizedBox(
                  width: w,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDeco(primary, radius: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${i + 1}', style: TextStyle(color: primary, fontSize: 44, fontWeight: FontWeight.w300, height: 1)),
                      const SizedBox(height: 14),
                      Text(steps[i].$1, style: const TextStyle(color: AppTheme.inkDark, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(steps[i].$2, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
                    ]),
                  ),
                ),
            ]);
          }),
        ]),
        v: 64,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Community: stats + vision / mission
// ---------------------------------------------------------------------------
class _Community extends StatelessWidget {
  final BrandingInfo brand;
  final int officialsCount;
  const _Community({required this.brand, required this.officialsCount});

  @override
  Widget build(BuildContext context) {
    final primary = brand.primary;
    final stats = <(String, String)>[
      if (officialsCount > 0) ('$officialsCount', 'Barangay officials'),
      ('24/7', 'Online access'),
    ];
    final vision = brand.vision.trim();
    final mission = brand.mission.trim();

    Widget card(String label, String text, {required bool filled}) => Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(minHeight: 200),
          decoration: filled
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(AppTheme.sunYellow.withValues(alpha: 0.24), Colors.white),
                      Color.alphaBlend(primary.withValues(alpha: 0.10), Colors.white),
                    ],
                  ),
                )
              : BoxDecoration(color: primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: filled ? shadeColor(primary, -0.28) : primary)),
              ),
              Icon(filled ? Icons.flag_outlined : Icons.visibility_outlined, color: filled ? shadeColor(primary, -0.28) : primary),
            ]),
            const SizedBox(height: 14),
            Text(text, style: const TextStyle(fontSize: 15.5, height: 1.55, color: AppTheme.inkDark)),
          ]),
        );

    return _page(
      Column(children: [
        _Heading('Aming komunidad', 'Isang barangay,\nisang pamayanan.'),
        const SizedBox(height: 28),
        Wrap(spacing: 56, runSpacing: 20, alignment: WrapAlignment.center, children: [
          for (final s in stats)
            Column(children: [
              Text(s.$1, style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1)),
              Text(s.$2, style: TextStyle(color: Colors.grey.shade600)),
            ]),
        ]),
        if (vision.isNotEmpty || mission.isNotEmpty) ...[
          const SizedBox(height: 36),
          LayoutBuilder(builder: (context, c) {
            final both = vision.isNotEmpty && mission.isNotEmpty;
            final cols = (c.maxWidth > 760 && both) ? 2 : 1;
            final w = (c.maxWidth - 18 * (cols - 1)) / cols;
            return Wrap(spacing: 18, runSpacing: 18, children: [
              if (vision.isNotEmpty) SizedBox(width: w, child: card('Vision', vision, filled: false)),
              if (mission.isNotEmpty) SizedBox(width: w, child: card('Mission', mission, filled: true)),
            ]);
          }),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Closing call to action
// ---------------------------------------------------------------------------
class _CtaCard extends StatelessWidget {
  const _CtaCard();

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final dark = shadeColor(primary, -0.38);
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('Ready to file your complaint?',
          style: TextStyle(color: Colors.white, fontSize: 30, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      SizedBox(height: 10),
      Text('Mag-create ng resident account at simulan ang iyong reklamo online.', style: TextStyle(color: Colors.white70, height: 1.45)),
    ]);
    final buttons = Wrap(spacing: 12, runSpacing: 12, children: [
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: dark, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16)),
        onPressed: () => context.go('/register'),
        child: const Text('Create account'),
      ),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16)),
        onPressed: () => context.go('/login'),
        child: const Text('Resident login'),
      ),
    ]);
    return _page(
      Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(28)),
        child: LayoutBuilder(builder: (context, c) {
          return c.maxWidth > 760
              ? Row(children: [Expanded(child: text), const SizedBox(width: 24), buttons])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 22), buttons]);
        }),
      ),
    );
  }
}
