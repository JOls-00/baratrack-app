/// Builds the assistant's greeting and suggested questions.
/// Greetings change with the time of day (Philippine time) and with the page the visitor is on.
class PortalGreeting {
  static DateTime _manilaNow() => DateTime.now().toUtc().add(const Duration(hours: 8));

  static String timeOfDay({bool isFil = true}) {
    final h = _manilaNow().hour;
    if (isFil) {
      if (h < 12) return 'Magandang umaga';
      if (h < 14) return 'Magandang tanghali';
      if (h < 18) return 'Magandang hapon';
      return 'Magandang gabi';
    }
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// Short line shown in the little bubble next to the chat button.
  static String teaser(String barangay, String page, {bool isFil = true}) {
    final hello = timeOfDay(isFil: isFil);
    if (!isFil) {
      switch (page) {
        case 'track':
          return '$hello! Need help tracking your complaint?';
        case 'faqs':
          return "$hello! Can't find the answer? Ask me.";
        case 'officials':
          return '$hello! Want to know how to reach the barangay office?';
        case 'contact':
          return '$hello! I can answer quick questions about the barangay hall.';
        default:
          return '$hello! I am the $barangay assistant. How can I help you?';
      }
    }
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
  static String opening(String barangay, String page, {bool isFil = true}) {
    final hello = timeOfDay(isFil: isFil);
    if (!isFil) {
      final extra = switch (page) {
        'track' => 'I can explain how to use Track Your Application.',
        'faqs' => 'You can ask me anything covered in the FAQs.',
        'contact' => 'Ask about office hours or how to contact the barangay hall.',
        _ => 'Ask me about filing or tracking a complaint, OTP, or office hours.',
      };
      return "$hello! I'm the $barangay BaraTrack assistant. $extra";
    }
    final extra = switch (page) {
      'track' => 'Kaya kong ipaliwanag kung paano gamitin ang Track Your Application.',
      'faqs' => 'Puwede mo akong tanungin tungkol sa laman ng FAQs.',
      'contact' => 'Itanong mo ang office hours o kung paano makipag-ugnayan sa barangay.',
      _ => 'Tanungin mo ako tungkol sa pag-file o pag-track ng reklamo, OTP, o office hours.',
    };
    return '$hello po! Ako ang BaraTrack assistant ng $barangay. $extra';
  }

  static List<String> suggestions(String page, {bool isFil = true}) {
    if (!isFil) {
      switch (page) {
        case 'track':
          return const ['Where do I find my reference number?', 'What is the difference between a complaint and a case?'];
        case 'faqs':
          return const ['I did not receive the OTP', 'I forgot my password'];
        case 'contact':
          return const ['What are the office hours?', 'How do I file a complaint?'];
        default:
          return const ['How do I file a complaint?', 'I did not receive the OTP', 'What are the office hours?'];
      }
    }
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
