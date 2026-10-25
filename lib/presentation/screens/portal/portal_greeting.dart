/// Builds the assistant's greeting and suggested questions.
/// Greetings change with the time of day (Philippine time) and with the page the visitor is on.
class PortalGreeting {
  static DateTime _manilaNow() => DateTime.now().toUtc().add(const Duration(hours: 8));

  static String timeOfDay() {
    final h = _manilaNow().hour;
    if (h < 12) return 'Magandang umaga';
    if (h < 14) return 'Magandang tanghali';
    if (h < 18) return 'Magandang hapon';
    return 'Magandang gabi';
  }

  /// Short line shown in the little bubble next to the chat button.
  static String teaser(String barangay, String page) {
    final hello = timeOfDay();
    switch (page) {
      case 'track':
        return '$hello po! Kailangan ng tulong sa pag-track ng reklamo mo?';
      case 'faqs':
        return '$hello po! Hindi mo makita ang sagot? Itanong mo sa akin.';
      case 'officials':
        return '$hello po! Gusto mo bang malaman kung paano makipag-ugnayan sa barangay?';
      case 'contact':
        return '$hello po! Ako na ang sasagot sa mga simpleng tanong tungkol sa barangay hall.';
      default:
        return '$hello po! Ako ang assistant ng $barangay. May maitutulong ba ako?';
    }
  }

  /// First message inside the chat.
  static String opening(String barangay, String page) {
    final hello = timeOfDay();
    final extra = switch (page) {
      'track' => 'Kaya kong ipaliwanag kung paano gamitin ang Track Your Application.',
      'faqs' => 'Puwede mo akong tanungin tungkol sa laman ng FAQs.',
      'contact' => 'Itanong mo ang office hours o kung paano makipag-ugnayan sa barangay.',
      _ => 'Tanungin mo ako tungkol sa pag-file o pag-track ng reklamo, OTP, o office hours.',
    };
    return '$hello po! Ako ang BaraTrack assistant ng $barangay. $extra';
  }

  static List<String> suggestions(String page) {
    switch (page) {
      case 'track':
        return const ['Saan ko makikita ang reference number ko?', 'Ano ang pagkakaiba ng reklamo at kaso?'];
      case 'faqs':
        return const ['Hindi dumating ang OTP', 'Nakalimutan ko ang password'];
      case 'contact':
        return const ['Ano ang office hours?', 'Paano mag-file ng reklamo?'];
      default:
        return const ['Paano mag-file ng reklamo?', 'Hindi dumating ang OTP', 'Ano ang office hours?'];
    }
  }
}
