import 'package:flutter/foundation.dart';
import '../../data/repositories/portal_repository.dart';

class PortalProvider with ChangeNotifier {
  final PortalRepository _repository;
  PortalProvider(this._repository);

  List<FaqCategory> _faqs = [];
  List<PortalAnnouncement> _announcements = [];
  bool _loading = false;
  bool _loaded = false;

  List<FaqCategory> get faqs => _faqs;
  List<PortalAnnouncement> get announcements => _announcements;
  bool get isLoading => _loading;

  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    notifyListeners();
    try {
      _faqs = await _repository.getFaqs();
    } catch (_) {}
    try {
      _announcements = await _repository.getAnnouncements();
    } catch (_) {}
    _loading = false;
    _loaded = true;
    notifyListeners();
  }

  Future<TrackResult> track(String reference, String lastName) =>
      _repository.track(reference.trim().toUpperCase(), lastName.trim());

  /// Tries the AI first; if it's off or fails, answers from the FAQs for free.
  Future<String> askAssistant(List<Map<String, String>> history) async {
    final ai = await _repository.chat(history);
    if (ai != null) return ai;
    final last = history.isNotEmpty ? (history.last['content'] ?? '') : '';
    return _localAnswer(last);
  }

  static const _stop = {
    'paano', 'ang', 'mga', 'ano', 'ako', 'the', 'how', 'what', 'and', 'for',
    'can', 'you', 'are', 'kung', 'may', 'mag', 'nang', 'para', 'ito', 'yung',
  };

  String _localAnswer(String question) {
    final words = question
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9ñ]+'))
        .where((w) => w.length > 2 && !_stop.contains(w))
        .toSet();

    FaqItem? best;
    var bestScore = 0;
    for (final cat in _faqs) {
      for (final item in cat.items) {
        final text = '${item.question} ${item.answer}'.toLowerCase();
        var score = 0;
        for (final w in words) {
          if (text.contains(w)) score++;
        }
        if (score > bestScore) {
          bestScore = score;
          best = item;
        }
      }
    }
    if (best != null && bestScore >= 1) return best.answer;
    return 'Pasensya na po, hindi ako sigurado sa sagot diyan. '
        'Pakitingnan ang FAQs, o magtanong po sa barangay office.';
  }
}
