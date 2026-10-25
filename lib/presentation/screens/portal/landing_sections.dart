import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../data/repositories/branding_repository.dart';
import '../../../data/repositories/portal_repository.dart';
import '../../providers/branding_provider.dart';

/// Darkens (negative) or lightens (positive) a colour; used to derive shades from the theme colour.
Color shadeColor(Color c, double delta) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + delta).clamp(0.0, 1.0)).toColor();
}

/// The admin-chosen theme colour.
Color brandPrimary(BuildContext context) => context.watch<BrandingProvider>().info.primary;

// ---------------------------------------------------------------------------
// Shared section frame
// ---------------------------------------------------------------------------
class SectionFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? background;

  const SectionFrame({required this.title, this.subtitle, required this.child, this.background});

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(subtitle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              ],
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// How it works
// ---------------------------------------------------------------------------
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final steps = [
      (Icons.person_add_alt_1, 'Create an account', 'Mag-register gamit ang iyong email at i-verify ito gamit ang code.'),
      (Icons.edit_note, 'File your complaint', 'Ilahad ang detalye at magdagdag ng ebidensya, online at kahit anong oras.'),
      (Icons.track_changes, 'Track the progress', 'Alamin ang status at petsa ng hearing gamit ang iyong reference number.'),
    ];
    return SectionFrame(
      title: 'How it works',
      subtitle: 'Tatlong simpleng hakbang para sa mabilis na serbisyo ng barangay.',
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 720 ? 3 : 1;
        final w = (c.maxWidth - 18 * (cols - 1)) / cols;
        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (var i = 0; i < steps.length; i++)
              SizedBox(
                width: w,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: primary.withValues(alpha: 0.12),
                              child: Icon(steps[i].$1, color: primary),
                            ),
                            const Spacer(),
                            Text('0${i + 1}',
                                style: TextStyle(
                                    fontSize: 34, fontWeight: FontWeight.w800, color: primary.withValues(alpha: 0.18))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(steps[i].$2, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(steps[i].$3, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// About
// ---------------------------------------------------------------------------
class AboutSection extends StatelessWidget {
  final BrandingInfo brand;
  const AboutSection({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    final primary = brand.primary;
    final about = brand.about.trim().isNotEmpty
        ? brand.about.trim()
        : 'Welcome to the official online portal of ${brand.name}, ${brand.city}. '
            'Here you can file complaints, track their progress, read announcements and get in touch with your barangay officials.';

    Widget card(IconData icon, String title, String text) => Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, color: primary),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text(text, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
              ],
            ),
          ),
        );

    final aside = <Widget>[
      if (brand.mission.trim().isNotEmpty) card(Icons.flag_outlined, 'Our Mission', brand.mission.trim()),
      if (brand.vision.trim().isNotEmpty) card(Icons.visibility_outlined, 'Our Vision', brand.vision.trim()),
    ];

    return SectionFrame(
      title: 'About ${brand.name}',
      subtitle: 'Kilalanin ang aming barangay',
      background: primary.withValues(alpha: 0.04),
      child: LayoutBuilder(builder: (context, c) {
        final text = Text(about, style: const TextStyle(fontSize: 16, height: 1.6));
        if (aside.isEmpty) return text;
        if (c.maxWidth > 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: text),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: Column(children: [for (final a in aside) Padding(padding: const EdgeInsets.only(bottom: 14), child: a)]),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [text, const SizedBox(height: 20), for (final a in aside) Padding(padding: const EdgeInsets.only(bottom: 14), child: a)],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Officials
// ---------------------------------------------------------------------------
class OfficialAvatar extends StatelessWidget {
  final Official official;
  final double size;
  const OfficialAvatar({super.key, required this.official, required this.size});

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    Widget initials() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.alphaBlend(primary.withValues(alpha: 0.10), Colors.white), Color.alphaBlend(primary.withValues(alpha: 0.24), Colors.white)],
            ),
          ),
          child: Text(official.initials,
              style: TextStyle(color: shadeColor(primary, -0.20), fontSize: size * 0.34, fontWeight: FontWeight.bold)),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primary.withValues(alpha: 0.5), width: 2)),
      child: ClipOval(
        child: official.hasPhoto
            ? Image.network(
                official.photoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initials(),
              )
            : initials(),
      ),
    );
  }
}

/// Elected officials are written "Hon. Name"; the Hon. is added here so initials stay correct.
String officialDisplayName(Official o) => (o.group == 'staff' || o.name.startsWith('Hon.')) ? o.name : 'Hon. ${o.name}';

class OfficialsSection extends StatelessWidget {
  final List<Official> officials;
  final Color? background;
  const OfficialsSection({super.key, required this.officials, this.background});

  @override
  Widget build(BuildContext context) {
    if (officials.isEmpty) return const SizedBox.shrink();
    final primary = brandPrimary(context);
    List<Official> of(String g) => officials.where((o) => o.group == g).toList();
    final captains = of('captain');

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 30, bottom: 16),
          child: Row(children: [
            Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: primary.withValues(alpha: 0.3))),
          ]),
        );

    Widget grid(List<Official> list) => Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final o in list)
              SizedBox(
                width: 190,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
                    child: Column(
                      children: [
                        OfficialAvatar(official: o, size: 84),
                        const SizedBox(height: 12),
                        Text(officialDisplayName(o), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(o.position,
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );

    return SectionFrame(
      title: 'Barangay Officials',
      subtitle: 'Ang inyong mga lingkod-bayan',
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (captains.isNotEmpty)
            Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  for (final o in captains)
                    Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.alphaBlend(const Color(0xFFF1FE0A).withValues(alpha: 0.22), Colors.white),
                            Color.alphaBlend(primary.withValues(alpha: 0.10), Colors.white),
                          ],
                        ),
                        border: Border.all(color: primary.withValues(alpha: 0.14)),
                        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white, border: Border.all(color: primary.withValues(alpha: 0.18))),
                            child: OfficialAvatar(official: o, size: 120),
                          ),
                          const SizedBox(height: 14),
                          Text(officialDisplayName(o),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF1F1416), fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(o.position.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: shadeColor(primary, -0.22), fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (of('council').isNotEmpty) ...[heading('Sangguniang Barangay'), grid(of('council'))],
          if (of('sk').isNotEmpty) ...[heading('Sangguniang Kabataan'), grid(of('sk'))],
          if (of('staff').isNotEmpty) ...[heading('Barangay Staff'), grid(of('staff'))],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Announcements
// ---------------------------------------------------------------------------
class AnnouncementsSection extends StatelessWidget {
  final List<PortalAnnouncement> items;
  const AnnouncementsSection({super.key, required this.items});

  String _date(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = brandPrimary(context);
    final list = items.take(6).toList();
    return SectionFrame(
      title: 'Announcements',
      subtitle: 'Mga balita at abiso mula sa barangay',
      background: primary.withValues(alpha: 0.04),
      child: list.isEmpty
          ? Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(children: [
                  Icon(Icons.campaign_outlined, color: primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Walang bagong announcement sa ngayon. Bumalik muli mamaya.')),
                ]),
              ),
            )
          : LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 760 ? 3 : (c.maxWidth > 480 ? 2 : 1);
              final w = (c.maxWidth - 16 * (cols - 1)) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final a in list)
                    SizedBox(
                      width: w,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 5, color: primary),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_date(a.createdAt).isNotEmpty)
                                    Text(_date(a.createdAt).toUpperCase(),
                                        style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: primary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(a.body, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact
// ---------------------------------------------------------------------------
class ContactSection extends StatelessWidget {
  final BrandingInfo brand;
  final VoidCallback onLogin;
  const ContactSection({super.key, required this.brand, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final primary = brand.primary;
    final rows = <(IconData, String, String)>[
      if (brand.address.trim().isNotEmpty) (Icons.location_on_outlined, 'Address', brand.address.trim()),
      if (brand.phone.trim().isNotEmpty) (Icons.phone_outlined, 'Phone', brand.phone.trim()),
      if (brand.email.trim().isNotEmpty) (Icons.mail_outline, 'Email', brand.email.trim()),
      if (brand.officeHours.trim().isNotEmpty) (Icons.schedule, 'Office hours', brand.officeHours.trim()),
    ];

    return SectionFrame(
      title: 'Contact Us',
      subtitle: 'Bisitahin o makipag-ugnayan sa barangay hall',
      child: rows.isEmpty
          ? Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(children: [
                  Icon(Icons.info_outline, color: primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Ilalagay ang contact details ng barangay dito sa lalong madaling panahon.')),
                ]),
              ),
            )
          : LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 760 ? 4 : (c.maxWidth > 480 ? 2 : 1);
              final w = (c.maxWidth - 16 * (cols - 1)) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final r in rows)
                    SizedBox(
                      width: w,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: primary.withValues(alpha: 0.12),
                                child: Icon(r.$1, color: primary),
                              ),
                              const SizedBox(height: 12),
                              Text(r.$2, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 2),
                              SelectableText(r.$3, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------
class SiteFooter extends StatelessWidget {
  final BrandingInfo brand;
  final VoidCallback onTrack;
  final VoidCallback onFaqs;
  final VoidCallback onLogin;
  const SiteFooter({super.key, required this.brand, required this.onTrack, required this.onFaqs, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final dark = shadeColor(brand.primary, -0.38);
    TextStyle link = const TextStyle(color: Colors.white70, fontSize: 13);
    return Container(
      width: double.infinity,
      color: dark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            children: [
              Wrap(
                spacing: 28,
                runSpacing: 20,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: const ClipOval(child: BrandLogo(size: 50)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BaraTrack', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('${brand.name}, ${brand.city}', style: link),
                          if (brand.slogan.trim().isNotEmpty)
                            Text(brand.slogan.trim(), style: link.copyWith(fontStyle: FontStyle.italic, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      TextButton(onPressed: onTrack, child: Text('Track a Complaint', style: link)),
                      TextButton(onPressed: onFaqs, child: Text('FAQs', style: link)),
                      TextButton(onPressed: onLogin, child: Text('Resident Login', style: link)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 36),
              Text('© ${DateTime.now().year} ${brand.name}, ${brand.city}. All rights reserved.',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Vision & Mission
// ---------------------------------------------------------------------------
class VisionMissionSection extends StatelessWidget {
  final BrandingInfo brand;
  const VisionMissionSection({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    final vision = brand.vision.trim();
    final mission = brand.mission.trim();
    if (vision.isEmpty && mission.isEmpty) return const SizedBox.shrink();
    final primary = brand.primary;

    Widget panel(IconData icon, String title, String text) => Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [shadeColor(primary, -0.30), primary],
            ),
            boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: const Color(0xFFF1FE0A)),
                const SizedBox(width: 10),
                Text(title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ]),
              const SizedBox(height: 14),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.55)),
            ],
          ),
        );

    return SectionFrame(
      title: 'Vision & Mission',
      subtitle: 'Ang aming pangarap at tungkulin para sa komunidad',
      child: LayoutBuilder(builder: (context, c) {
        final cols = (c.maxWidth > 760 && vision.isNotEmpty && mission.isNotEmpty) ? 2 : 1;
        final w = (c.maxWidth - 18 * (cols - 1)) / cols;
        return Wrap(spacing: 18, runSpacing: 18, children: [
          if (vision.isNotEmpty) SizedBox(width: w, child: panel(Icons.visibility_outlined, 'Vision', vision)),
          if (mission.isNotEmpty) SizedBox(width: w, child: panel(Icons.flag_outlined, 'Mission', mission)),
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Brief history
// ---------------------------------------------------------------------------
class HistorySection extends StatefulWidget {
  final BrandingInfo brand;
  const HistorySection({super.key, required this.brand});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.brand.history.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final primary = widget.brand.primary;
    final paras = text.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    final shown = _open ? paras : paras.take(2).toList();
    return SectionFrame(
      title: 'Brief History of the Barangay',
      subtitle: 'Ang pinagmulan ng ${widget.brand.name}',
      background: primary.withValues(alpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: primary, width: 4))),
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(p, style: const TextStyle(fontSize: 15.5, height: 1.7)),
                  ),
              ],
            ),
          ),
          if (paras.length > 2)
            TextButton.icon(
              onPressed: () => setState(() => _open = !_open),
              icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
              label: Text(_open ? 'Show less' : 'Read the full history'),
            ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Album (barangay photos; links are set by the admin in Settings)
// ---------------------------------------------------------------------------
class AlbumSection extends StatelessWidget {
  final BrandingInfo brand;
  final int? limit; // null = show all (Album page)
  final bool showEmptyNote;
  const AlbumSection({super.key, required this.brand, this.limit, this.showEmptyNote = false});

  void _open(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = brand.albumUrls;
    if (all.isEmpty && !showEmptyNote) return const SizedBox.shrink();
    final urls = limit == null ? all : all.take(limit!).toList();
    final primary = brand.primary;
    return SectionFrame(
      title: 'Album',
      subtitle: 'Mga larawan ng ${brand.name}',
      child: all.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(18)),
              child: const Text('Wala pang larawan sa album. Idadagdag ito ng barangay.'),
            )
          : Column(
              children: [
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 760 ? 3 : (c.maxWidth > 480 ? 2 : 1);
                  const gap = 14.0;
                  final w = (c.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(spacing: gap, runSpacing: gap, children: [
                    for (final u in urls)
                      SizedBox(
                        width: w,
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _open(context, u),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                u,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: primary.withValues(alpha: 0.08),
                                  child: Icon(Icons.broken_image_outlined, color: primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]);
                }),
                if (limit != null && all.length > limit!)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: TextButton.icon(
                      onPressed: () => context.go('/album'),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('View the full album'),
                    ),
                  ),
              ],
            ),
    );
  }
}
