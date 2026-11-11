import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

/// 3-Step First-Time Walkthrough (Task 38)
/// Skippable onboarding flow covering:
/// 1. Step-by-Step Filing
/// 2. Case Timeline Tracking
/// 3. Offline Mode & Drafts
class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeWalkthrough() async {
    try {
      final user = context.read<AuthProvider>().user;
      final prefs = await SharedPreferences.getInstance();
      final key = user != null ? 'walkthrough_seen_${user.id}' : 'walkthrough_seen_general';
      await prefs.setBool(key, true);
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = context.watch<LocaleProvider>();
    final isFil = locale.isFilipino;

    final slides = [
      (
        icon: Icons.assignment_turned_in_outlined,
        color: AppTheme.brand500,
        title: isFil ? '1. Paghahain ng Reklamo' : '1. Step-by-Step Filing',
        desc: isFil
            ? 'Mabilis at may gabay na pag-file ng sumbong o alitan sa Lupon gamit ang 5-step form (Sino, Ano, Saan, Ebidensya, Pagsusuri).'
            : 'Guided, step-by-step blotter filing (Who, What, Where, Evidence, Review) ensuring complete details for the Lupon.',
      ),
      (
        icon: Icons.timeline_rounded,
        color: AppTheme.burstBlue,
        title: isFil ? '2. Pagsubaybay sa Kaso' : '2. Status & Hearing Tracker',
        desc: isFil
            ? 'Subaybayan ang bawat yugto ng iyong reklamo mula sa pagkahain, mediation hearing, hanggang sa maayos na resolusyon.'
            : 'Track your complaint from filing to Lupon mediation sessions and final resolution in real-time.',
      ),
      (
        icon: Icons.offline_pin_rounded,
        color: AppTheme.success,
        title: isFil ? '3. Offline Mode & Drafts' : '3. Offline Resilience',
        desc: isFil
            ? 'Kahit walang internet o mahina ang signal sa Purok, ligtas na nase-save ang iyong mga draft at awtomatikong magsi-sync kapag online.'
            : 'Never lose your progress. Save offline drafts anytime and automatically sync when connectivity returns.',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.scaffoldDark : AppTheme.scaffoldLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _completeWalkthrough,
            child: Text(
              isFil ? 'Laktawan (Skip)' : 'Skip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final s = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: isDark ? 0.2 : 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: s.color.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Icon(s.icon, size: 54, color: s.color),
                        ),
                        const SizedBox(height: AppTheme.space32),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          s.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? (isDark ? AppTheme.crimsonDarkAccent : AppTheme.brand500)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space32),
            // Bottom Action Button (Min height 48px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeWalkthrough();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentPage < slides.length - 1
                        ? (isFil ? 'SUSUNOD' : 'NEXT')
                        : (isFil ? 'SIMULAN NA' : 'GET STARTED'),
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
