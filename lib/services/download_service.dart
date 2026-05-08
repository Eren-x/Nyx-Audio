import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import 'database_service.dart';
import 'log_service.dart';

class DownloadService {
  static DownloadService? _instance;
  DownloadService._();
  static DownloadService get instance {
    _instance ??= DownloadService._();
    return _instance!;
  }

  bool _running = false;
  final _queue = <Track>[];
  void Function(Track track, double progress)? onProgress;
  void Function(Track track, bool success)? onComplete;

  Future<Directory> get _musicDir async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'music'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<bool> get ytDlpAvailable async {
    try {
      final res = await Process.run('yt-dlp', ['--version']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> get spotiFLACAvailable async {
    try {
      // SpotiFLAC may be in the PATH or a bundled binary
      final res = await Process.run('spotiflac', ['--version']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void enqueue(Track track) {
    if (!_queue.any((t) => t.id == track.id)) {
      _queue.add(track);
    }
    if (!_running) _processQueue();
  }

  void enqueueAll(List<Track> tracks) {
    for (final t in tracks) {
      if (!_queue.any((q) => q.id == t.id)) _queue.add(t);
    }
    if (!_running) _processQueue();
  }

  Future<void> _processQueue() async {
    _running = true;
    while (_queue.isNotEmpty) {
      final track = _queue.removeAt(0);
      await _download(track);
    }
    _running = false;
  }

  Future<void> _download(Track track) async {
    await DatabaseService.instance.updateTrackStatus(
        track.id, DownloadStatus.downloading);

    try {
      final dir = await _musicDir;
      final safeArtist =
          track.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final safeTitle =
          track.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final outPath =
          p.join(dir.path, '$safeArtist - $safeTitle.%(ext)s');

      final searchQuery =
          '${track.artist} ${track.title} audio';

      // Try yt-dlp first
      final success = await _runYtDlp(track, searchQuery, outPath, dir);

      if (success) {
        await LogService.instance.log(
          SyncLogTypeAlias.download,
          'Downloaded "${track.title}" by ${track.artist}',
        );
        onComplete?.call(track, true);
      } else {
        await DatabaseService.instance.updateTrackStatus(
            track.id, DownloadStatus.failed);
        await LogService.instance.log(
          SyncLogTypeAlias.error,
          'Failed to download "${track.title}" by ${track.artist}',
        );
        onComplete?.call(track, false);
      }
    } catch (e) {
      await DatabaseService.instance.updateTrackStatus(
          track.id, DownloadStatus.failed);
      onComplete?.call(track, false);
    }
  }

  Future<bool> _runYtDlp(
      Track track, String query, String outTemplate, Directory dir) async {
    try {
      final safeArtist =
          track.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final safeTitle =
          track.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final process = await Process.start('yt-dlp', [
        'ytsearch1:$query',
        '--extract-audio',
        '--audio-format', 'flac',
        '--audio-quality', '0',
        '--embed-thumbnail',
        '--add-metadata',
        '--metadata-from-title', '%(artist)s - %(title)s',
        '-o', outTemplate,
        '--no-playlist',
      ]);

      await process.exitCode;

      // Find the downloaded file
      final expectedFlac =
          p.join(dir.path, '$safeArtist - $safeTitle.flac');
      final file = File(expectedFlac);
      if (await file.exists()) {
        await DatabaseService.instance.updateTrackStatus(
          track.id,
          DownloadStatus.downloaded,
          syncStatus: SyncStatus.notSynced,
          filePath: file.path,
        );
        return true;
      }

      // Check for any file matching the pattern
      final files = await dir.list().toList();
      for (final f in files) {
        if (f.path
            .contains('$safeArtist - $safeTitle')) {
          await DatabaseService.instance.updateTrackStatus(
            track.id,
            DownloadStatus.downloaded,
            syncStatus: SyncStatus.notSynced,
            filePath: f.path,
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  int get queueLength => _queue.length;
  bool get isRunning => _running;
}
