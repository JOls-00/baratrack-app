import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/locale_provider.dart';

/// App-wide Localization dictionary for English and Filipino (Tagalog).
/// Adheres to Task 29: Centralized strings, including floating tabs, headers, actions,
/// validation messages, and emergency labels.
class AppStrings {
  static const String localeEn = 'en';
  static const String localeFil = 'fil';

  static final Map<String, Map<String, String>> _values = {
    localeFil: {
      // Common & Navigation
      'app_title': 'BaraTrack',
      'tab_home': 'Home',
      'tab_calendar': 'Kalendaryo',
      'tab_complaints': 'Reklamo',
      'tab_hearings': 'Hearings',
      'tab_dashboard': 'Dashboard',
      'tab_inbox': 'Inbox',
      'tab_cases': 'Mga Kaso',
      'tab_more': 'Iba Pa',
      
      // Top bar & Status
      'online': 'Online',
      'offline': 'Offline',
      'hotlines': 'Hotlines',
      'notifications': 'Mga Abiso',
      'mark_all_read': 'Basahin Lahat',
      'clear_all': 'Burahin Lahat',
      'no_notifications': 'Walang bagong abiso.',

      // Emergency
      'emergency_title': '🆘 Mga Hotline sa Emergency',
      'emergency_subtitle': '24/7 na mga numerong matatawagan sa oras ng sakuna o kagipitan sa Barangay Rosario.',
      'call_now': 'Tumawag',
      'pnp_police': 'Pulisya (PNP)',
      'tanod': 'Barangay Tanod',
      'rescue_cdrmmo': 'Rescue / CDRRMO',
      'fire_station': 'Bumbero (BFP)',

      // Resident Home & Complaints
      'welcome_resident': 'Mabuhay!',
      'file_complaint_card_title': 'Maghain ng Reklamo',
      'file_complaint_card_sub': 'Ipaabot ang iyong sumbong o alitan sa Lupon Tagapamayapa ng Barangay Rosario sa pamamagitan ng mabilisang step-by-step form.',
      'file_now': 'MAGHAIN NGAYON',
      'next_hearing': 'SUSUNOD NA PAGDINIG (HEARING)',
      'no_next_hearing': 'Walang Nakaiskedyul na Pagdinig',
      'no_next_hearing_sub': 'Lahat ng iyong kaso ay napakinggan na o naghihintay ng Lupon review.',
      'unsent_drafts_warning': 'Mayroon kang hindi pa nai-sync na reklamo',
      'view_drafts': 'Tingnan',
      'active_case': 'Aktibong Kaso',
      'no_active_case': 'Walang Aktibong Kaso',
      'no_active_case_sub': 'Wala kang patuloy na legal proceeding o pagdinig sa kasalukuyan.',
      'my_complaints_title': 'Aking mga Naihaing Reklamo',
      'my_complaints_sub': 'Kasaysayan ng lahat ng blotter at reklamong iyong isinumite.',

      // Hearings & Calendar
      'hearing_schedule': 'Iskedyul ng Pagdinig',
      'mediation_session': 'Paghaharap / Mediation',
      'add_to_calendar': 'Idagdag sa Kalendaryo',
      'calendar_added_success': 'Binubuksan ang iyong Kalendaryo para itala ang schedule...',
      'acknowledge_schedule': 'Tanggapin ang Iskedyul',

      // Settings & Walkthrough
      'settings_title': 'Mga Setting',
      'settings_sub': 'Pamahalaan ang account, tema, at wika ng app.',
      'language_section': 'Wika (Language)',
      'lang_filipino': 'Filipino (Tagalog)',
      'lang_english': 'English',
      'walkthrough_button': 'Tingnan ang App Walkthrough Guide',
      'logout': 'Mag-sign Out',
      'unsent_drafts_logout_prompt': 'May mga draft ka pang hindi nai-sync. Sigurado ka bang magla-log out?',

      // Admin & Filter
      'command_center': 'Command Center',
      'today_hearings': 'Mga Pagdinig Ngayong Araw',
      'pending_inbox': 'Mga Bagong Reklamo (Inbox)',
      'filter_all': 'Lahat',
      'filter_pending': 'Pending',
      'filter_investigation': 'Sinusuri',
      'filter_settled': 'Naayos',
      'filter_closed': 'Isinara',
      'search_cases_hint': 'Maghanap ayon sa case number, pangalan, o detalye...',
    },
    localeEn: {
      // Common & Navigation
      'app_title': 'BaraTrack',
      'tab_home': 'Home',
      'tab_calendar': 'Calendar',
      'tab_complaints': 'Complaints',
      'tab_hearings': 'Hearings',
      'tab_dashboard': 'Dashboard',
      'tab_inbox': 'Inbox',
      'tab_cases': 'Cases',
      'tab_more': 'More',

      // Top bar & Status
      'online': 'Online',
      'offline': 'Offline',
      'hotlines': 'Hotlines',
      'notifications': 'Notifications',
      'mark_all_read': 'Mark All Read',
      'clear_all': 'Clear All',
      'no_notifications': 'No notifications yet.',

      // Emergency
      'emergency_title': '🆘 Emergency Hotlines',
      'emergency_subtitle': '24/7 emergency response contacts for Barangay Rosario residents.',
      'call_now': 'Call',
      'pnp_police': 'Police (PNP)',
      'tanod': 'Barangay Tanod',
      'rescue_cdrmmo': 'Rescue / CDRRMO',
      'fire_station': 'Fire Dept (BFP)',

      // Resident Home & Complaints
      'welcome_resident': 'Welcome!',
      'file_complaint_card_title': 'File a Complaint',
      'file_complaint_card_sub': 'Submit a blotter report or dispute to the Lupon Tagapamayapa of Barangay Rosario via the guided step-by-step form.',
      'file_now': 'FILE NOW',
      'next_hearing': 'NEXT SCHEDULED HEARING',
      'no_next_hearing': 'No Hearings Scheduled',
      'no_next_hearing_sub': 'All your cases have been heard or are awaiting Lupon review.',
      'unsent_drafts_warning': 'You have unsent offline drafts',
      'view_drafts': 'View',
      'active_case': 'Active Case',
      'no_active_case': 'No Active Cases',
      'no_active_case_sub': 'You have no ongoing legal proceedings at this time.',
      'my_complaints_title': 'My Filed Complaints',
      'my_complaints_sub': 'History of all blotter reports you have submitted.',

      // Hearings & Calendar
      'hearing_schedule': 'Hearing Schedule',
      'mediation_session': 'Mediation Session',
      'add_to_calendar': 'Add to Calendar',
      'calendar_added_success': 'Opening your calendar to save this schedule...',
      'acknowledge_schedule': 'Acknowledge Schedule',

      // Settings & Walkthrough
      'settings_title': 'Settings',
      'settings_sub': 'Manage your account, theme, and app preferences.',
      'language_section': 'Language',
      'lang_filipino': 'Filipino (Tagalog)',
      'lang_english': 'English',
      'walkthrough_button': 'View App Walkthrough Guide',
      'logout': 'Sign Out',
      'unsent_drafts_logout_prompt': 'You have unsent offline drafts. Logging out will clear your offline cache. Log out anyway?',

      // Admin & Filter
      'command_center': 'Command Center',
      'today_hearings': "Today's Hearings",
      'pending_inbox': 'Pending Complaints (Inbox)',
      'filter_all': 'All',
      'filter_pending': 'Pending',
      'filter_investigation': 'Investigation',
      'filter_settled': 'Settled',
      'filter_closed': 'Closed',
      'search_cases_hint': 'Search by case number, name, or details...',
    },
  };

  /// Returns translated string based on languageCode ('en' or 'fil').
  /// Fallbacks to English, then returns the key itself if untranslated.
  static String get(String key, String languageCode) {
    final langMap = _values[languageCode] ?? _values[localeFil]!;
    return langMap[key] ?? _values[localeEn]?[key] ?? key;
  }
}

extension AppStringsContext on BuildContext {
  /// Quick helper to get string using the active LocaleProvider
  String tr(String key) {
    try {
      final loc = watch<LocaleProvider>();
      return loc.tr(key);
    } catch (_) {
      return AppStrings.get(key, 'fil');
    }
  }
}
