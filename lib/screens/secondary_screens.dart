import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/track.dart';
import '../models/models.dart';
import '../theme/nyx_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/dap_sync_service.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);

    final filtered = switch (_filter) {
      'synced' => tracks
          .where((t) => t.syncStatus == SyncStatus.synced)
          .toList(),
      'pending' => tracks
          .where((t) =>
              t.syncStatus != SyncStatus.synced &&
              t.downloadStatus == DownloadStatus.downloaded)
          .toList(),
      'liked' => tracks.where((t) => t.liked).toList(),
      _ => tracks,
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Library', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text('${tracks.length} tracks · sorted by date added',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('all', 'All'),
              const SizedBox(width: 8),
              _filterChip('synced', 'Synced'),
              const SizedBox(width: 8),
              _filterChip('pending', 'Pending sync'),
              const SizedBox(width: 8),
              _filterChip('liked', 'Liked'),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: filtered.isEmpty
            ? const EmptyState(
                icon: Icons.library_music_rounded,
                title: 'No tracks',
                subtitle: 'Discover music or import from Spotify',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => Dismissible(
                  key: Key(filtered[i].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                        color: NyxColors.errorBg,
                        borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: NyxColors.error),
                  ),
                  onDismissed: (_) => ref
                      .read(tracksProvider.notifier)
                      .removeTrack(filtered[i].id),
                  child: TrackRow(
                    track: filtered[i],
                    index: i,
                    showStatus: true,
                  ),
                ),
              ),
      ),
    ]);
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? NyxColors.primaryDim : NyxColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  selected ? NyxColors.borderBright : NyxColors.border,
              width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? NyxColors.primaryText
                  : NyxColors.textMuted,
            )),
      ),
    );
  }
}

// ── Playlists Screen ─────────────────────────────────────────────────────────

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final tracks = ref.watch(tracksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Playlists',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                      '${playlists.length} playlists · imported + created',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
          ),
          OutlinedButton.icon(
            onPressed: () => _createPlaylist(context, ref),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New'),
          ),
        ]),
        const SizedBox(height: 16),
        if (playlists.isEmpty)
          const EmptyState(
            icon: Icons.playlist_play_rounded,
            title: 'No playlists yet',
            subtitle: 'Create one or import from Spotify',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: playlists.length,
            itemBuilder: (ctx, i) {
              final pl = playlists[i];
              final syncedCount = pl.trackIds
                  .where((id) => tracks.any((t) =>
                      t.id == id &&
                      t.syncStatus == SyncStatus.synced))
                  .length;
              return NyxCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(pl.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: NyxColors.primaryText),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                          '${pl.trackIds.length} tracks · $syncedCount synced',
                          style: NyxText.trackArtist),
                    ]),
              );
            },
          ),
      ]),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    String name = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NyxColors.surface,
        title: const Text('New Playlist',
            style: TextStyle(color: NyxColors.textPrimary, fontSize: 16)),
        content: TextField(
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Playlist name'),
          onChanged: (v) => name = v,
          style: const TextStyle(color: NyxColors.textPrimary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: NyxColors.textMuted))),
          ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  ref.read(playlistsProvider.notifier).addPlaylist(
                      Playlist(name: name));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create')),
        ],
      ),
    );
  }
}

// ── DAP Sync Screen ──────────────────────────────────────────────────────────

class DapSyncScreen extends ConsumerWidget {
  const DapSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(dapDeviceProvider);
    final syncProgress = ref.watch(syncProgressProvider);
    final stats = ref.watch(libraryStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DAP Sync', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
            device != null
                ? '${device.name} · Connected'
                : 'No device connected',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),

        // Device card
        NyxCard(
          borderColor:
              device != null ? NyxColors.borderBright : NyxColors.border,
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
              Text(device?.name ?? 'Snowsky Echo Mini',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: NyxColors.primaryText)),
              Text(
                  device != null
                      ? '${device.totalFormatted} · ${device.usedFormatted} used · ${device.freeFormatted} free'
                      : 'Plug in your DAP via USB',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
            const Spacer(),
            device != null
                ? const NyxPill('Connected', style: NyxPillStyle.green)
                : const NyxPill('Disconnected',
                    style: NyxPillStyle.gray),
          ]),
        ),

        // Storage bar
        if (device != null) ...[
          const SizedBox(height: 12),
          NyxCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Storage'),
                  const SizedBox(height: 4),
                  NyxProgressBar(value: device.usedPercent, height: 6),
                  const SizedBox(height: 6),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${device.usedFormatted} used',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(device.totalFormatted,
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                ]),
          ),
        ],

        const SizedBox(height: 12),

        // Stats row
        stats.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (s) => Row(children: [
            Expanded(
                child: NyxCard(
                    child: Column(children: [
              Text('${s.synced}',
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: NyxColors.primaryText)),
              const SizedBox(height: 3),
              Text('tracks on DAP',
                  style: Theme.of(context).textTheme.bodySmall),
            ]))),
            const SizedBox(width: 10),
            Expanded(
                child: NyxCard(
                    borderColor: s.pendingSync > 0
                        ? NyxColors.borderBright
                        : NyxColors.border,
                    child: Column(children: [
              Text('${s.pendingSync}',
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: NyxColors.primaryText)),
              const SizedBox(height: 3),
              Text('pending sync',
                  style: Theme.of(context).textTheme.bodySmall),
            ]))),
            const SizedBox(width: 10),
            Expanded(
                child: NyxCard(
                    child: Column(children: [
              const Text('0',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: NyxColors.success)),
              const SizedBox(height: 3),
              Text('errors',
                  style: Theme.of(context).textTheme.bodySmall),
            ]))),
          ]),
        ),

        const SizedBox(height: 16),

        // Sync progress
        if (syncProgress.running) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Expanded(
              child: Text(
                  syncProgress.currentTrack.isNotEmpty
                      ? 'Syncing "${syncProgress.currentTrack}"…'
                      : 'Preparing…',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('${(syncProgress.percent * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 6),
          NyxProgressBar(value: syncProgress.percent, height: 6),
          const SizedBox(height: 12),
        ],

        if (device != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: syncProgress.running ? null : () => _sync(context, ref),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              child: stats.when(
                loading: () => const Text('Sync to DAP'),
                error: (_, __) => const Text('Sync to DAP'),
                data: (s) => Text(s.pendingSync > 0
                    ? 'Sync ${s.pendingSync} Pending Tracks to ${device.name}'
                    : 'All tracks synced ✓'),
              ),
            ),
          ),
      ]),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncProgressProvider.notifier);
    final tracks = ref.read(tracksProvider);
    final pending = tracks
        .where((t) =>
            t.syncStatus != SyncStatus.synced &&
            t.downloadStatus == DownloadStatus.downloaded)
        .toList();

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to sync.')));
      return;
    }

    notifier.start(pending.length);
    final result = await DapSyncService.instance.syncPending(
      onProgress: (done, total, track) {
        notifier.update(done, total, track);
      },
    );
    notifier.finish(result.message);
    ref.read(tracksProvider.notifier).refresh();
    ref.read(syncLogsProvider.notifier).refresh();
  }
}

// ── Logs Screen ───────────────────────────────────────────────────────────────

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(syncLogsProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sync Logs',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text('Full history of every sync action',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
          ),
          OutlinedButton(
              onPressed: () =>
                  ref.read(syncLogsProvider.notifier).clear(),
              child: const Text('Clear')),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: logs.isEmpty
            ? const EmptyState(
                icon: Icons.history_rounded,
                title: 'No logs yet',
                subtitle: 'Sync activity will appear here')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: logs.length,
                itemBuilder: (ctx, i) {
                  final log = logs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _logColor(log.type)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(log.message,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: NyxColors.textSecondary)),
                                    if (log.details != null)
                                      Text(log.details!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: NyxColors.textMuted)),
                                    const NyxDivider(),
                                  ]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(log.timeFormatted,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: NyxColors.textGhost)),
                          ),
                        ]),
                  );
                },
              ),
      ),
    ]);
  }

  Color _logColor(SyncLogType t) {
    return switch (t) {
      SyncLogType.sync => NyxColors.success,
      SyncLogType.download => NyxColors.primary,
      SyncLogType.connect => NyxColors.success,
      SyncLogType.error => NyxColors.error,
      _ => NyxColors.textMuted,
    };
  }
}
