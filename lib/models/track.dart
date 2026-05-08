import 'package:uuid/uuid.dart';

enum DownloadStatus { pending, downloading, downloaded, failed }

enum SyncStatus { pending, synced, notSynced }

class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? albumArtUrl;
  final int? durationMs;
  String? filePath;
  final String? format;
  final int? sampleRate;
  final int? bitDepth;
  DownloadStatus downloadStatus;
  SyncStatus syncStatus;
  final String source; // 'spotify', 'lastfm', 'manual'
  final String? spotifyId;
  final String? lastfmMbid;
  int playCount;
  DateTime? lastPlayed;
  final DateTime addedAt;
  bool liked;

  Track({
    String? id,
    required this.title,
    required this.artist,
    this.album,
    this.albumArtUrl,
    this.durationMs,
    this.filePath,
    this.format,
    this.sampleRate,
    this.bitDepth,
    this.downloadStatus = DownloadStatus.pending,
    this.syncStatus = SyncStatus.notSynced,
    this.source = 'manual',
    this.spotifyId,
    this.lastfmMbid,
    this.playCount = 0,
    this.lastPlayed,
    DateTime? addedAt,
    this.liked = false,
  })  : id = id ?? const Uuid().v4(),
        addedAt = addedAt ?? DateTime.now();

  Track copyWith({
    String? filePath,
    DownloadStatus? downloadStatus,
    SyncStatus? syncStatus,
    int? playCount,
    DateTime? lastPlayed,
    bool? liked,
    String? format,
  }) {
    return Track(
      id: id,
      title: title,
      artist: artist,
      album: album,
      albumArtUrl: albumArtUrl,
      durationMs: durationMs,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      sampleRate: sampleRate,
      bitDepth: bitDepth,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      source: source,
      spotifyId: spotifyId,
      lastfmMbid: lastfmMbid,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      addedAt: addedAt,
      liked: liked ?? this.liked,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'album_art_url': albumArtUrl,
        'duration_ms': durationMs,
        'file_path': filePath,
        'format': format,
        'sample_rate': sampleRate,
        'bit_depth': bitDepth,
        'download_status': downloadStatus.name,
        'sync_status': syncStatus.name,
        'source': source,
        'spotify_id': spotifyId,
        'lastfm_mbid': lastfmMbid,
        'play_count': playCount,
        'last_played': lastPlayed?.millisecondsSinceEpoch,
        'added_at': addedAt.millisecondsSinceEpoch,
        'liked': liked ? 1 : 0,
      };

  factory Track.fromMap(Map<String, dynamic> map) => Track(
        id: map['id'] as String,
        title: map['title'] as String,
        artist: map['artist'] as String,
        album: map['album'] as String?,
        albumArtUrl: map['album_art_url'] as String?,
        durationMs: map['duration_ms'] as int?,
        filePath: map['file_path'] as String?,
        format: map['format'] as String?,
        sampleRate: map['sample_rate'] as int?,
        bitDepth: map['bit_depth'] as int?,
        downloadStatus: DownloadStatus.values.byName(
            map['download_status'] as String? ?? 'pending'),
        syncStatus: SyncStatus.values
            .byName(map['sync_status'] as String? ?? 'notSynced'),
        source: map['source'] as String? ?? 'manual',
        spotifyId: map['spotify_id'] as String?,
        lastfmMbid: map['lastfm_mbid'] as String?,
        playCount: map['play_count'] as int? ?? 0,
        lastPlayed: map['last_played'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_played'] as int)
            : null,
        addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
        liked: (map['liked'] as int? ?? 0) == 1,
      );

  String get durationFormatted {
    if (durationMs == null) return '--:--';
    final s = durationMs! ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  String get qualityLabel {
    if (format == null) return '';
    if (sampleRate != null && bitDepth != null) {
      return '${format!} ${bitDepth}bit/${(sampleRate! / 1000).round()}kHz';
    }
    return format!;
  }
}
