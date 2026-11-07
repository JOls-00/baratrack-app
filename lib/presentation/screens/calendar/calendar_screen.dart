import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../data/models/case_model.dart';
import '../../../data/models/hearing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/hearing_provider.dart';

enum _CalView { month, week, day }

/// One entry on the calendar: either a complaint (by incident date) or a hearing.
class _Ev {
  final DateTime day;
  final int minutes;
  final String timeLabel;
  final String title;
  final String subtitle;
  final bool hearing;
  final String status;
  final Color color;
  final int? caseId;

  const _Ev({
    required this.day,
    required this.minutes,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.hearing,
    required this.status,
    required this.color,
    this.caseId,
  });
}

String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Understands "14:30", "14:30:00" and "2:30 PM".
({int minutes, String label}) _parseTime(String raw) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$', caseSensitive: false).firstMatch(raw.trim());
  if (m == null) return (minutes: 0, label: raw.trim());
  var h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  final ap = m.group(3)?.toUpperCase();
  if (ap == 'PM' && h < 12) h += 12;
  if (ap == 'AM' && h == 12) h = 0;
  return (minutes: h * 60 + min, label: DateFormat('h:mm a').format(DateTime(2000, 1, 1, h % 24, min)));
}

Color _statusColor(String status, bool dark) {
  switch (status) {
    case 'Pending':
      return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    case 'Reviewed':
      return dark ? const Color(0xFF7AA2FF) : const Color(0xFF1D4ED8);
    case 'Converted to Case':
      return dark ? const Color(0xFFB59CFF) : const Color(0xFF6D28D9);
    case 'Dismissed':
      return dark ? const Color(0xFFA3AEC0) : const Color(0xFF475569);
    case 'Scheduled':
      return dark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    case 'Completed':
      return dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    case 'Postponed':
      return dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    default:
      return dark ? const Color(0xFFA3AEC0) : const Color(0xFF64748B);
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  _CalView _view = _CalView.month;
  late final DateTime _today;
  late DateTime _cur;
  late DateTime _sel;
  bool _showComplaints = true;
  bool _showHearings = true;
  bool _isResident = true;
  Map<String, List<_Ev>> _byDay = {};

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _today = DateTime(n.year, n.month, n.day);
    _cur = _today;
    _sel = _today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    context.read<ComplaintProvider>().fetchMyComplaints();
    context.read<HearingProvider>().fetchHearings();
  }

  Map<String, List<_Ev>> _group(List<ComplaintModel> cs, List<HearingModel> hs, bool dark) {
    final map = <String, List<_Ev>>{};
    void add(_Ev e) => map.putIfAbsent(_key(e.day), () => <_Ev>[]).add(e);

    for (final c in cs) {
      final t = _parseTime(c.incidentTime);
      add(_Ev(
        day: DateTime(c.incidentDate.year, c.incidentDate.month, c.incidentDate.day),
        minutes: t.minutes,
        timeLabel: t.label,
        title: c.typeName,
        subtitle: c.incidentLocation,
        hearing: false,
        status: c.status,
        color: _statusColor(c.status, dark),
        caseId: c.caseId,
      ));
    }
    for (final h in hs) {
      final t = _parseTime(h.hearingTime);
      add(_Ev(
        day: DateTime(h.hearingDate.year, h.hearingDate.month, h.hearingDate.day),
        minutes: t.minutes,
        timeLabel: t.label,
        title: h.caseNumber.isNotEmpty ? 'Hearing: ${h.caseNumber}' : 'Hearing',
        subtitle: h.venue,
        hearing: true,
        status: h.status,
        color: _statusColor(h.status, dark),
        caseId: h.caseId,
      ));
    }
    for (final list in map.values) {
      list.sort((a, b) => a.minutes.compareTo(b.minutes));
    }
    return map;
  }

  List<_Ev> _eventsOn(DateTime d) {
    final all = _byDay[_key(d)] ?? <_Ev>[];
    return all.where((e) => e.hearing ? _showHearings : _showComplaints).toList();
  }

  void _move(int n) {
    setState(() {
      switch (_view) {
        case _CalView.month:
          _cur = DateTime(_cur.year, _cur.month + n, 1);
          break;
        case _CalView.week:
          _cur = DateTime(_cur.year, _cur.month, _cur.day + 7 * n);
          break;
        case _CalView.day:
          _cur = DateTime(_cur.year, _cur.month, _cur.day + n);
          _sel = _cur;
          break;
      }
    });
  }

  void _select(DateTime d) {
    setState(() {
      _sel = d;
      if (_view == _CalView.month && d.month != _cur.month) _cur = DateTime(d.year, d.month, 1);
    });
  }

  void _open(_Ev e) {
    if (e.hearing) {
      context.go(_isResident ? '/my-hearings' : '/hearings-mgmt');
    } else if (!_isResident && e.caseId != null) {
      context.go('/cases/${e.caseId}');
    } else {
      context.go(_isResident ? '/my-complaints' : '/complaints-inbox');
    }
  }

  String _title() {
    if (_view == _CalView.month) return DateFormat('MMMM yyyy').format(_cur);
    if (_view == _CalView.week) {
      final s = DateTime(_cur.year, _cur.month, _cur.day - _cur.weekday % 7);
      final e = DateTime(s.year, s.month, s.day + 6);
      return '${DateFormat('MMM d').format(s)} – ${DateFormat('MMM d, yyyy').format(e)}';
    }
    return DateFormat('EEEE, MMMM d').format(_cur);
  }

  @override
  Widget build(BuildContext context) {
    final complaints = context.watch<ComplaintProvider>();
    final hearings = context.watch<HearingProvider>();
    _isResident = context.watch<AuthProvider>().user?.role == 'Resident';
    final dark = Theme.of(context).brightness == Brightness.dark;
    _byDay = _group(complaints.myComplaints, hearings.hearings, dark);
    final loading = complaints.isLoading || hearings.isLoading;
    final failed = complaints.error != null || hearings.error != null;
    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final calendar = _calendarCard(context, wide);
      final panel = _panelCard(context);
      return RefreshIndicator(
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(wide ? 24 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendar', style: theme.textTheme.headlineMedium),
              Text(
                'Track your barangay complaints and hearings',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 12),
              if (loading) const LinearProgressIndicator(minHeight: 3),
              if (failed && !loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Some items could not be loaded. Pull down to try again.',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 4),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: calendar),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: panel),
                  ],
                )
              else
                Column(children: [calendar, const SizedBox(height: 12), panel]),
            ],
          ),
        ),
      );
    });
  }

  Widget _calendarCard(BuildContext context, bool wide) {
    final theme = Theme.of(context);
    final Widget body = _view == _CalView.month
        ? _monthGrid(context, wide)
        : _view == _CalView.week
            ? _weekView(context, wide)
            : _dayList(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(wide ? 16 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(_title(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<_CalView>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: _CalView.month, label: Text('Month')),
                        ButtonSegment(value: _CalView.week, label: Text('Week')),
                        ButtonSegment(value: _CalView.day, label: Text('Day')),
                      ],
                      selected: {_view},
                      onSelectionChanged: (s) => setState(() {
                        _view = s.first;
                        if (_view == _CalView.day) _cur = _sel;
                      }),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _cur = _today;
                        _sel = _today;
                      }),
                      child: const Text('Today'),
                    ),
                    IconButton(tooltip: 'Previous', icon: const Icon(Icons.chevron_left), onPressed: () => _move(-1)),
                    IconButton(tooltip: 'Next', icon: const Icon(Icons.chevron_right), onPressed: () => _move(1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Complaints'),
                  selected: _showComplaints,
                  onSelected: (v) => setState(() => _showComplaints = v),
                ),
                FilterChip(
                  label: const Text('Hearings'),
                  selected: _showHearings,
                  onSelected: (v) => setState(() => _showHearings = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }

  // ---------- Month ----------
  Widget _monthGrid(BuildContext context, bool wide) {
    final theme = Theme.of(context);
    final first = DateTime(_cur.year, _cur.month, 1);
    final last = DateTime(_cur.year, _cur.month + 1, 0);
    var d = DateTime(first.year, first.month, first.day - first.weekday % 7); // week starts on Sunday

    final rows = <Widget>[
      Row(
        children: [
          for (final x in const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Text(
                    x,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ];
    while (!d.isAfter(last) || d.weekday != DateTime.sunday) {
      final week = <Widget>[];
      for (var i = 0; i < 7; i++) {
        week.add(_dayCell(context, d, wide));
        d = DateTime(d.year, d.month, d.day + 1);
      }
      rows.add(Row(children: week));
    }
    return Column(children: rows);
  }

  Widget _dayCell(BuildContext context, DateTime d, bool wide) {
    final theme = Theme.of(context);
    final es = _eventsOn(d);
    final inMonth = d.month == _cur.month;
    final isToday = _sameDay(d, _today);
    final isSel = _sameDay(d, _sel);

    return Expanded(
      child: InkWell(
        onTap: () => _select(d),
        child: Container(
          height: wide ? 108 : 58,
          padding: EdgeInsets.all(wide ? 6 : 4),
          decoration: BoxDecoration(
            color: isSel ? context.brand.withValues(alpha: 0.10) : null,
            border: Border.all(color: isSel ? context.brand : theme.dividerColor, width: isSel ? 2 : 0.5),
          ),
          child: Opacity(
            opacity: inMonth ? 1 : 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isToday ? context.brand : null),
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (wide) ...[
                  for (final e in es.take(3)) _chip(e),
                  if (es.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '+ ${es.length - 3} more',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                ] else if (es.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: [
                        for (final e in es.take(5))
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: e.color)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(_Ev e) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: e.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(5)),
        child: Row(
          children: [
            Container(width: 3, height: 16, color: e.color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${e.timeLabel.replaceAll(' ', '').toLowerCase()} ${e.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Week ----------
  Widget _weekView(BuildContext context, bool wide) {
    final weekStart = DateTime(_cur.year, _cur.month, _cur.day - _cur.weekday % 7);
    final cols = [
      for (var i = 0; i < 7; i++) _weekColumn(context, DateTime(weekStart.year, weekStart.month, weekStart.day + i)),
    ];
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in cols) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: c)),
        ],
      );
    }
    return Column(
      children: [for (final c in cols) Padding(padding: const EdgeInsets.only(bottom: 8), child: c)],
    );
  }

  Widget _weekColumn(BuildContext context, DateTime d) {
    final theme = Theme.of(context);
    final es = _eventsOn(d);
    final isSel = _sameDay(d, _sel);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _select(d),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? context.brand : theme.dividerColor, width: isSel ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d').format(d) + (_sameDay(d, _today) ? ' • Today' : ''),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (es.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('No items',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              )
            else
              for (final e in es) _chip(e),
          ],
        ),
      ),
    );
  }

  // ---------- Day ----------
  Widget _dayList(BuildContext context) {
    final es = _eventsOn(_cur);
    if (es.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Nothing scheduled this day.', style: TextStyle(color: Theme.of(context).hintColor))),
      );
    }
    return Column(children: [for (final e in es) _itemTile(context, e)]);
  }

  // ---------- Side panel ----------
  Widget _panelCard(BuildContext context) {
    final theme = Theme.of(context);
    final es = _eventsOn(_sel);
    final isToday = _sameDay(_sel, _today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isToday ? 'Today’s items' : 'Items for this day',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormat('EEEE, MMMM d').format(_sel),
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.go(_isResident ? '/my-complaints' : '/cases'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 24),
            if (es.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Nothing scheduled.', style: TextStyle(color: theme.hintColor))),
              )
            else
              for (final e in es) _itemTile(context, e),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(BuildContext context, _Ev e) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _open(e),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.timeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (e.subtitle.isNotEmpty)
                    Text(
                      e.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: e.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
              child: Text(e.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: e.color)),
            ),
          ],
        ),
      ),
    );
  }
}
