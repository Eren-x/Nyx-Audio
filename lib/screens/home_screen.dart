import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/track.dart';
import '../theme/nyx_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/dap_sync_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(dapDeviceProvider);
    final stats = ref.watch(libraryStatsProvider);
    final tracks = ref.watch(tracksProvider);
    final syncProgress = ref.watch(syncProgressProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning.'
        : hour < 17
            ? 'Good afternoon.'
            : 'Good evening.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(greeting,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text('Your library is ready.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),

        // Stat cards
        stats.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (s) => Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Tracks',
                    value: '${s.total}',
                    sub: '+${tracks.where((t) => t.addedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length} this week')),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'On DAP',
                    value: '${s.synced}',
                    sub: '${s.pendingSync} pending sync')),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Storage',
                    value: device?.usedFormatted ?? '--',
                    sub: device != null
                        ? 'of ${device.totalFormatted} used'
                        : 'No device')),
          ]),
        ),

        const SizedBox(height: 20),
        const SectionLabel('Device'),

        // DAP card
        NyxCard(
          borderColor: device != null
              ? NyxColors.borderBright
              : NyxColors.border,
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: NyxColors.primaryDim,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.phone_android_rounded,
                  size: 18, color: NyxColors.primaryText),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  device?.name ?? 'Snowsky Echo Mini',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: NyxColors.primaryText)),
              Text(
                  device != null
                      ? 'Connected · USB · ${device.totalFormatted}'
                      : 'Plug in your DAP to sync',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
            const Spacer(),
            if (device != null)
              const NyxPill('Connected', style: NyxPillStyle.green),
            if (device == null)
              const NyxPill('Disconnected', style: NyxPillStyle.gray),
            const SizedBox(width: 10),
            if (device != null)
              ElevatedButton(
                onPressed: syncProgress.running
                    ? null
                    : () => _runSync(context, ref),
                child: Text(
                    syncProgress.running ? 'Syncing…' : 'Sync Now'),
              ),
          ]),
        ),

        // Sync progress bar
        if (syncProgress.running) ...[
          const SizedBox(height: 12),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  syncProgress.currentTrack.isNotEmpty
                      ? 'Syncing "${syncProgress.currentTrack}"…'
                      : 'Preparing sync…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(syncProgress.percent * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
          const SizedBox(height: 4),
          NyxProgressBar(value: syncProgress.percent),
        ],

        if (syncProgress.message != null && !syncProgress.running) ...[
          const SizedBox(height: 12),
          NyxCard(
            borderColor: NyxColors.successBg,
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: NyxColors.success),
              const SizedBox(width: 8),
              Text(syncProgress.message!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: NyxColors.success)),
            ]),
          ),
        ],

        const SizedBox(height: 20),
        const SectionLabel('Recently added'),

        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyState(
              icon: Icons.music_note_rounded,
              title: 'No tracks yet',
              subtitle: 'Search for music or import from Spotify',
            ),
          )
        else
          ...tracks.take(8).toList().asMap().entries.map((entry) =>
              TrackRow(
                  track: entry.value,
                  index: entry.key,
                  showStatus: true)),
      ]),
    );
  }

  Future<void> _runSync(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncProgressProvider.notifier);
    final pending = ref.read(tracksProvider)
        .where((t) =>
            t.syncStatus != SyncStatus.synced &&
            t.downloadStatus == DownloadStatus.downloaded)
        .toList();

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to sync right now.')));
      return;
    }

    notifier.start(pending.length);

    final result =
        await DapSyncService.instance.syncPending(onProgress: (done, total, track) {
      notifier.update(done, total, track);
      ref.read(tracksProvider.notifier).refresh();
    });

    notifier.finish(result.message);
    ref.read(tracksProvider.notifier).refresh();
    ref.read(syncLogsProvider.notifier).refresh();
  }
}
