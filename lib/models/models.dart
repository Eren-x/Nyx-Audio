import 'package:uuid/uuid.dart';
import 'track.dart';

class Playlist {
  final String id;
  String name;
  String? description;
  final String source;
  final String? spotifyId;
  final DateTime createdAt;
  DateTime updatedAt;
  List<String> trackIds;

  Playlist({
    String? id,
    required this.name,
    this.description,
    this.source = 'manual',
    this.spotifyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? trackIds,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        trackIds = trackIds ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'source': source,
        'spotify_id': spotifyId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Playlist.fromMap(Map<String, dynamic> map) => Playlist(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        source: map['source'] as String? ?? 'manual',
        spotifyId: map['spotify_id'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            map['updated_at'] as int),
      );
}

enum SyncLogType { sync, download, importLog, connect, error, info }

class SyncLog {
  final int? id;
  final SyncLogType type;
  final String message;
  final String? details;
  final DateTime timestamp;

  const SyncLog({
    this.id,
    required this.type,
    required this.message,
    this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'message': message,
        'details': details,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory SyncLog.fromMap(Map<String, dynamic> map) => SyncLog(
        id: map['id'] as int?,
        type: SyncLogType.values.byName(map['type'] as String? ?? 'info'),
        message: map['message'] as String,
        details: map['details'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            map['timestamp'] as int),
      );

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays == 0) {
      return 'Today ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class LastFmTrack {
  final String name;
  final String artist;
  final String? album;
  final String? imageUrl;
  final String? mbid;
  final int? durationMs;
  final int? listeners;

  const LastFmTrack({
    required this.name,
    required this.artist,
    this.album,
    this.imageUrl,
    this.mbid,
    this.durationMs,
    this.listeners,
  });

  factory LastFmTrack.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    final images = json['image'] as List?;
    if (images != null && images.isNotEmpty) {
      final large = images.lastWhere(
        (i) => (i['size'] as String?) == 'extralarge',
        orElse: () => images.last,
      );
      final url = large['#text'] as String?;
      if (url != null && url.isNotEmpty) imageUrl = url;
    }

    int? duration;
    final durStr = json['duration'] as String?;
    if (durStr != null && durStr.isNotEmpty) {
      final secs = int.tryParse(durStr);
      if (secs != null) duration = secs * 1000;
    }

    return LastFmTrack(
      name: json['name'] as String? ?? '',
      artist: (json['artist'] is Map
              ? (json['artist'] as Map)['name']
              : json['artist']) as String? ??
          '',
      album: (json['album'] is Map
          ? (json['album'] as Map)['#text']
          : json['album']) as String?,
      imageUrl: imageUrl,
      mbid: json['mbid'] as String?,
      durationMs: duration,
      listeners: int.tryParse(json['listeners']?.toString() ?? ''),
    );
  }

  Track toTrack() => Track(
        title: name,
        artist: artist,
        album: album,
        albumArtUrl: imageUrl,
        durationMs: durationMs,
        lastfmMbid: mbid,
        source: 'lastfm',
      );
}

class DapDevice {
  final String name;
  final String mountPath;
  final int totalBytes;
  final int usedBytes;

  const DapDevice({
    required this.name,
    required this.mountPath,
    required this.totalBytes,
    required this.usedBytes,
  });

  int get freeBytes => totalBytes - usedBytes;
  double get usedPercent => totalBytes > 0 ? usedBytes / totalBytes : 0;

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  String get totalFormatted => _formatBytes(totalBytes);
  String get usedFormatted => _formatBytes(usedBytes);
  String get freeFormatted => _formatBytes(freeBytes);
}
