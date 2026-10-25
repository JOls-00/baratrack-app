import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/case_provider.dart';
import '../../presentation/providers/complaint_provider.dart';
import '../../presentation/providers/documents_provider.dart';
import '../../presentation/providers/evidence_provider.dart';
import '../../presentation/providers/hearing_provider.dart';
import '../../presentation/providers/navigation_provider.dart';
import '../../presentation/providers/notification_provider.dart';
import '../../presentation/providers/reports_provider.dart';
import '../../presentation/providers/resident_provider.dart';
import '../../presentation/providers/user_provider.dart';

/// Clears every user-specific provider whenever someone logs in or out, so one account's data
/// (hearings, cases, complaints, ...) can never show up in the next account's session.
/// Wrap the app with it once, below the MultiProvider.
class SessionResetBinder extends StatefulWidget {
  final Widget child;
  const SessionResetBinder({super.key, required this.child});

  @override
  State<SessionResetBinder> createState() => _SessionResetBinderState();
}

class _SessionResetBinderState extends State<SessionResetBinder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().registerSessionReset(_resetAll);
    });
  }

  void _resetAll() {
    if (!mounted) return;
    context.read<CaseProvider>().reset();
    context.read<ComplaintProvider>().reset();
    context.read<DocumentsProvider>().reset();
    context.read<EvidenceProvider>().reset();
    context.read<HearingProvider>().reset();
    context.read<NavigationProvider>().reset();
    context.read<NotificationProvider>().reset();
    context.read<ReportsProvider>().reset();
    context.read<ResidentProvider>().reset();
    context.read<UserProvider>().reset();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
