import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/track.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'log_service.dart';

class DapSyncService {
  static DapSyncService? _instance;
  DapSyncService._();
  static DapSyncService get instance {
    _instance ??= DapSyncService._();
    return _instance!;
  }

  DapDevice? _connected;
  DapDevice? get connectedDevice => _connected;
  bool get isConnected => _connected != null;

  void Function(DapDevice?)? onDeviceChanged;
  void Function(int done, int total, String currentTrack)? onSyncProgress;

  /// Scan macOS /Volumes for removable DAP devices
  Future<DapDevice?> detectDevice() async {
    if (!Platform.isMacOS) return null;
    try {
      final volumes = Directory('/Volumes');
      final dirs = await volumes.list().toList();
      for (final entity in dirs) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        if (name == 'Macintosh HD' || name.startsWith('.')) continue;

        // Check if it looks like a DAP (has Music folder or is small enough)
        final musicDir = Directory(p.join(entity.path, 'Music'));
        final musicExists = await musicDir.exists();

        // Get disk usage via df
        final df = await Process.run('df', ['-k', entity.path]);
        if (df.exitCode != 0) continue;
        final lines = (df.stdout as String).trim().split('\n');
        if (lines.length < 2) continue;
        final parts =
            lines.last.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        if (parts.length < 4) continue;

        final totalKb = int.tryParse(parts[1]) ?? 0;
        final usedKb = int.tryParse(parts[2]) ?? 0;

        // Likely a DAP if < 512 GB
        if (totalKb > 0 && totalKb < 512 * 1024 * 1024) {
          _connected = DapDevice(
            name: name,
            mountPath: entity.path,
            totalBytes: totalKb * 1024,
            usedBytes: usedKb * 1024,
          );
          onDeviceChanged?.call(_connected);
          await LogService.instance.log(
            SyncLogTypeAlias.connect,
            '$name connected · ${_connected!.totalFormatted} · ${_connected!.usedFormatted} used',
          );
          return _connected;
        }
      }
    } catch (_) {}
    if (_connected != null) {
      _connected = null;
      onDeviceChanged?.call(null);
    }
    return null;
  }

  /// Poll for device every 3 seconds
  void startPolling() {
    Future.doWhile(() async {
      await detectDevice();
      await Future.delayed(const Duration(seconds: 3));
      return true;
    });
  }

  /// Sync all pending tracks to DAP
  Future<SyncResult> syncPending({
    void Function(int done, int total, String track)? onProgress,
  }) async {
    if (_connected == null) {
      return SyncResult(success: false, message: 'No device connected');
    }

    final device = _connected!;
    final pending = await DatabaseService.instance.getPendingSync();

    if (pending.isEmpty) {
      return SyncResult(success: true, message: 'Nothing to sync');
    }

    // Ensure Music folder exists on DAP
    final musicDir =
        Directory(p.join(device.mountPath, 'Music'));
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }

    int done = 0;
    int failed = 0;
    int totalBytes = 0;

    for (final track in pending) {
      if (track.filePath == null) continue;
      final src = File(track.filePath!);
      if (!await src.exists()) {
        failed++;
        continue;
      }

      try {
        // Organise into Artist/Album subfolders
        final safeArtist =
            track.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final safeAlbum = (track.album ?? 'Unknown Album')
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final destDir = Directory(
            p.join(musicDir.path, safeArtist, safeAlbum));
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        final fileName = p.basename(track.filePath!);
        final dest = File(p.join(destDir.path, fileName));

        await src.copy(dest.path);
        totalBytes += await src.length();

        await DatabaseService.instance.updateTrackStatus(
          track.id,
          DownloadStatus.downloaded,
          syncStatus: SyncStatus.synced,
        );

        done++;
        onProgress?.call(done, pending.length, track.title);
      } catch (e) {
        failed++;
      }
    }

    final msg =
        'Synced $done tracks to ${device.name} · ${_formatBytes(totalBytes)} transferred';
    await LogService.instance.log(SyncLogTypeAlias.sync, msg);

    return SyncResult(
      success: true,
      message: msg,
      synced: done,
      failed: failed,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  void dispose() {
    _connected = null;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int synced;
  final int failed;

  const SyncResult({
    required this.success,
    required this.message,
    this.synced = 0,
    this.failed = 0,
  });
}
