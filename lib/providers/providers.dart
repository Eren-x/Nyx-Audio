import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/lastfm_service.dart';
import '../services/dap_sync_service.dart';
import '../services/download_service.dart';
import '../services/log_service.dart';

// ── Services ──────────────────────────────────────────────────────────────

final lastFmServiceProvider = Provider((_) => LastFmService());

final dapSyncServiceProvider = Provider((ref) {
  final service = DapSyncService.instance;
  service.startPolling();
  return service;
});

// ── DAP device ────────────────────────────────────────────────────────────

final dapDeviceProvider =
    StateNotifierProvider<DapDeviceNotifier, DapDevice?>(
        (ref) => DapDeviceNotifier(ref));

class DapDeviceNotifier extends StateNotifier<DapDevice?> {
  DapDeviceNotifier(this._ref) : super(null) {
    final service = _ref.read(dapSyncServiceProvider);
    service.onDeviceChanged = (device) => state = device;
  }
  final Ref _ref;
}

// ── Library ───────────────────────────────────────────────────────────────

final tracksProvider =
    StateNotifierProvider<TracksNotifier, List<Track>>(
        (ref) => TracksNotifier());

class TracksNotifier extends StateNotifier<List<Track>> {
  TracksNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await DatabaseService.instance.getAllTracks();
  }

  Future<void> addTrack(Track track) async {
    await DatabaseService.instance.insertTrack(track);
    state = [track, ...state];
    DownloadService.instance.enqueue(track);
  }

  Future<void> addTracks(List<Track> tracks) async {
    await DatabaseService.instance.insertTracks(tracks);
    state = [...tracks, ...state];
    DownloadService.instance.enqueueAll(
        tracks.where((t) => t.downloadStatus == DownloadStatus.pending).toList());
  }

  Future<void> removeTrack(String id) async {
    await DatabaseService.instance.deleteTrack(id);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> toggleLike(String id) async {
    await DatabaseService.instance.toggleLiked(id);
    state = state
        .map((t) => t.id == id ? t.copyWith(liked: !t.liked) : t)
        .toList();
  }

  void updateTrackInState(Track updated) {
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
  }

  Future<void> refresh() => load();
}

// ── Library stats ─────────────────────────────────────────────────────────

final libraryStatsProvider = FutureProvider<LibraryStats>((ref) async {
  ref.watch(tracksProvider); // rebuild when tracks change
  final total = await DatabaseService.instance.getTrackCount();
  final synced = await DatabaseService.instance.getSyncedCount();
  final pending = await DatabaseService.instance.getPendingSyncCount();
  return LibraryStats(total: total, synced: synced, pendingSync: pending);
});

class LibraryStats {
  final int total;
  final int synced;
  final int pendingSync;
  const LibraryStats(
      {required this.total, required this.synced, required this.pendingSync});
}

// ── Playlists ─────────────────────────────────────────────────────────────

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, List<Playlist>>(
        (ref) => PlaylistsNotifier());

class PlaylistsNotifier extends StateNotifier<List<Playlist>> {
  PlaylistsNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await DatabaseService.instance.getAllPlaylists();
  }

  Future<void> addPlaylist(Playlist playlist) async {
    await DatabaseService.instance.insertPlaylist(playlist);
    state = [playlist, ...state];
  }

  Future<void> deletePlaylist(String id) async {
    await DatabaseService.instance.deletePlaylist(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> addTrackToPlaylist(
      String playlistId, String trackId) async {
    await DatabaseService.instance
        .addTrackToPlaylist(playlistId, trackId);
    await load();
  }
}

// ── Sync logs ─────────────────────────────────────────────────────────────

final syncLogsProvider =
    StateNotifierProvider<SyncLogsNotifier, List<SyncLog>>(
        (ref) => SyncLogsNotifier());

class SyncLogsNotifier extends StateNotifier<List<SyncLog>> {
  SyncLogsNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await LogService.instance.getLogs();
  }

  Future<void> refresh() => load();

  Future<void> clear() async {
    await DatabaseService.instance.clearLogs();
    state = [];
  }
}

// ── Search ────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<LastFmTrack>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 400)); // debounce
  return ref.read(lastFmServiceProvider).search(query);
});

final similarArtistsProvider =
    FutureProvider.family<List<String>, String>((ref, artist) async {
  return ref.read(lastFmServiceProvider).getSimilarArtists(artist);
});

// ── Sync progress ─────────────────────────────────────────────────────────

final syncProgressProvider =
    StateNotifierProvider<SyncProgressNotifier, SyncProgress>(
        (ref) => SyncProgressNotifier());

class SyncProgressNotifier extends StateNotifier<SyncProgress> {
  SyncProgressNotifier() : super(const SyncProgress());

  void start(int total) =>
      state = SyncProgress(running: true, total: total, done: 0);

  void update(int done, int total, String current) =>
      state = SyncProgress(
          running: true, total: total, done: done, currentTrack: current);

  void finish(String message) =>
      state = SyncProgress(running: false, message: message);

  void reset() => state = const SyncProgress();
}

class SyncProgress {
  final bool running;
  final int total;
  final int done;
  final String currentTrack;
  final String? message;

  const SyncProgress({
    this.running = false,
    this.total = 0,
    this.done = 0,
    this.currentTrack = '',
    this.message,
  });

  double get percent => total > 0 ? done / total : 0;
}

// ── Navigation ────────────────────────────────────────────────────────────

enum AppPage { home, discover, library, playlists, dapSync, importPage, logs }

final activePageProvider =
    StateProvider<AppPage>((ref) => AppPage.home);

// ── Download queue indicator ──────────────────────────────────────────────

final downloadQueueProvider = StreamProvider<int>((ref) async* {
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    yield DownloadService.instance.queueLength;
  }
});
