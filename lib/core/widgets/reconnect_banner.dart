import 'package:flutter/material.dart';
import '../router/app_router.dart';

class ReconnectBanner extends StatelessWidget {
  final int draftCount;
  final VoidCallback? onProceed;

  const ReconnectBanner({
    super.key,
    this.draftCount = 0,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: const Color(0xFF1B5E20), // Forest green
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 350;

              final textWidget = Row(
                children: [
                  const Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      draftCount > 0
                          ? 'Your internet is back ($draftCount unsent draft${draftCount > 1 ? 's' : ''})'
                          : 'Your internet is back',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );

              final actionBtn = ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: onProceed ?? () => AppRouter.exitOfflineMode(),
                child: const Text(
                  'Proceed to Online Mode',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              );

              if (isVeryNarrow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    textWidget,
                    const SizedBox(height: 6),
                    SizedBox(width: double.infinity, child: actionBtn),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: textWidget),
                  const SizedBox(width: 8),
                  actionBtn,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
