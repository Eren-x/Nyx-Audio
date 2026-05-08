import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/nyx_theme.dart';
import '../widgets/nyx_logo.dart';
import '../widgets/shared_widgets.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'secondary_screens.dart';
import 'import_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(activePageProvider);
    final device = ref.watch(dapDeviceProvider);
    final downloadQueue = ref.watch(downloadQueueProvider);

    return Scaffold(
      backgroundColor: NyxColors.bg,
      body: Row(children: [
        // Sidebar
        Container(
          width: 180,
          decoration: const BoxDecoration(
            color: NyxColors.surfaceAlt,
            border: Border(
                right: BorderSide(color: NyxColors.border, width: 0.5)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: NyxLogo(size: 28, showWordmark: true),
            ),
            const NyxDivider(),
            const SizedBox(height: 8),

            _sectionLabel('Main'),
            _navItem(context, ref, page, AppPage.home,
                Icons.home_rounded, 'Home'),
            _navItem(context, ref, page, AppPage.discover,
                Icons.search_rounded, 'Discover'),
            _navItem(context, ref, page, AppPage.library,
                Icons.library_music_rounded, 'Library'),
            _navItem(context, ref, page, AppPage.playlists,
                Icons.playlist_play_rounded, 'Playlists'),

            const SizedBox(height: 4),
            _sectionLabel('Sync'),
            _navItem(context, ref, page, AppPage.dapSync,
                Icons.phone_android_rounded, 'DAP Sync',
                indicator: device != null
                    ? const _GreenDot()
                    : null),
            _navItem(context, ref, page, AppPage.importPage,
                Icons.download_rounded, 'Import'),
            _navItem(context, ref, page, AppPage.logs,
                Icons.receipt_long_rounded, 'Sync Logs'),

            const Spacer(),

            // Download queue badge
            downloadQueue.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => count > 0
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      child: NyxCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        borderColor: NyxColors.borderBright,
                        child: Row(children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: NyxColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count downloading',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: NyxColors.textSecondary)),
                        ]),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const NyxDivider(),
            const SizedBox(height: 8),
          ]),
        ),

        // Main content
        Expanded(
          child: _pageFor(page),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: NyxColors.textGhost,
                letterSpacing: 0.12)),
      );

  Widget _navItem(
    BuildContext context,
    WidgetRef ref,
    AppPage current,
    AppPage target,
    IconData icon,
    String label, {
    Widget? indicator,
  }) {
    final active = current == target;
    return InkWell(
      onTap: () =>
          ref.read(activePageProvider.notifier).state = target,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: active ? NyxColors.primaryDim : Colors.transparent,
          border: Border(
              left: BorderSide(
                  color: active
                      ? NyxColors.primary
                      : Colors.transparent,
                  width: 2)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(children: [
          Icon(icon,
              size: 16,
              color: active
                  ? NyxColors.primaryText
                  : NyxColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: active
                      ? NyxColors.primaryText
                      : NyxColors.textSecondary)),
          if (indicator != null) ...[
            const Spacer(),
            indicator,
          ],
        ]),
      ),
    );
  }

  Widget _pageFor(AppPage page) {
    return switch (page) {
      AppPage.home => const HomeScreen(),
      AppPage.discover => const DiscoverScreen(),
      AppPage.library => const LibraryScreen(),
      AppPage.playlists => const PlaylistsScreen(),
      AppPage.dapSync => const DapSyncScreen(),
      AppPage.importPage => const ImportScreen(),
      AppPage.logs => const LogsScreen(),
    };
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: NyxColors.success),
      );
}
