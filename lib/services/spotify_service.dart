import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/track.dart';
import '../models/models.dart';

class SpotifyService {
  static const _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const _redirectUri = 'http://localhost:8888/callback';
  static const _scopes =
      'user-library-read playlist-read-private user-read-private';

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<bool> get isAuthenticated async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');
    final expMs = prefs.getInt('spotify_token_expiry');
    if (_accessToken == null || expMs == null) return false;
    _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expMs);
    return _tokenExpiry!.isAfter(DateTime.now());
  }

  /// Opens Spotify login in browser, starts local server to catch token
  Future<bool> authenticate() async {
    final completer = Completer<String?>();
    HttpServer? server;

    try {
      server = await HttpServer.bind('localhost', 8888);

      final uri = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': _clientId,
        'response_type': 'token',
        'redirect_uri': _redirectUri,
        'scope': _scopes,
      });
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Wait for the redirect with a timeout
      server.listen((request) {
        final html = '''
<html><body>
<script>
  const hash = window.location.hash.substring(1);
  const params = new URLSearchParams(hash);
  const token = params.get('access_token');
  const expires = params.get('expires_in');
  fetch('/token?access_token=' + token + '&expires_in=' + expires)
    .then(() => { document.body.innerHTML = '<h2 style="font-family:sans-serif;text-align:center;margin-top:40px;color:#7c3aed">✓ Nyx Audio connected.<br><small style="color:#888">You can close this tab.</small></h2>'; });
</script>
<p style="font-family:sans-serif;text-align:center;margin-top:40px">Connecting to Nyx Audio...</p>
</body></html>''';

        if (request.uri.path == '/callback') {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(html);
          request.response.close();
        } else if (request.uri.path == '/token') {
          final token = request.uri.queryParameters['access_token'];
          final expires = request.uri.queryParameters['expires_in'];
          request.response
            ..statusCode = 200
            ..write('ok');
          request.response.close();
          if (!completer.isCompleted) {
            completer.complete('$token::$expires');
          }
        }
      });

      final result = await completer.future
          .timeout(const Duration(minutes: 3), onTimeout: () => null);

      if (result != null && result.contains('::')) {
        final parts = result.split('::');
        final token = parts[0];
        final expires = int.tryParse(parts[1]) ?? 3600;
        await saveToken(token, expires);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      await server?.close(force: true);
    }
  }

  Future<void> launchAuth() => authenticate();

  Future<void> saveToken(String token, int expiresIn) async {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_access_token', token);
    await prefs.setInt(
        'spotify_token_expiry', _tokenExpiry!.millisecondsSinceEpoch);
  }

  Future<void> logout() async {
    _accessToken = null;
    _tokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_token_expiry');
  }

  Future<Map<String, String>> _headers() async => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  Future<List<Track>> getLikedSongs(
      {void Function(int done, int total)? onProgress}) async {
    final tracks = <Track>[];
    String? url =
        'https://api.spotify.com/v1/me/tracks?limit=50&offset=0';
    int total = 0;
    while (url != null) {
      final res =
          await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      total = json['total'] as int? ?? 0;
      final items = (json['items'] as List?) ?? [];
      for (final item in items) {
        final t = (item as Map)['track'] as Map<String, dynamic>?;
        if (t == null) continue;
        tracks.add(_spotifyTrackToTrack(t));
      }
      onProgress?.call(tracks.length, total);
      url = json['next'] as String?;
    }
    return tracks;
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final playlists = <Map<String, dynamic>>[];
    String? url =
        'https://api.spotify.com/v1/me/playlists?limit=50&offset=0';
    while (url != null) {
      final res =
          await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      playlists.addAll(
          ((json['items'] as List?) ?? [])
              .cast<Map<String, dynamic>>());
      url = json['next'] as String?;
    }
    return playlists;
  }

  Future<List<Track>> getPlaylistTracks(String playlistId,
      {void Function(int, int)? onProgress}) async {
    final tracks = <Track>[];
    String? url =
        'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=100';
    int total = 0;
    while (url != null) {
      final res =
          await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      total = json['total'] as int? ?? 0;
      final items = (json['items'] as List?) ?? [];
      for (final item in items) {
        final t = (item as Map)['track'] as Map<String, dynamic>?;
        if (t == null) continue;
        tracks.add(_spotifyTrackToTrack(t));
      }
      onProgress?.call(tracks.length, total);
      url = json['next'] as String?;
    }
    return tracks;
  }

  Track _spotifyTrackToTrack(Map<String, dynamic> t) {
    String? imageUrl;
    final album = t['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    if (images != null && images.isNotEmpty) {
      imageUrl = (images.first as Map)['url'] as String?;
    }
    final artists =
        ((t['artists'] as List?) ?? []).cast<Map<String, dynamic>>();
    final artistNames =
        artists.map((a) => a['name'] as String).join(', ');
    return Track(
      title: t['name'] as String? ?? '',
      artist: artistNames,
      album: album?['name'] as String?,
      albumArtUrl: imageUrl,
      durationMs: t['duration_ms'] as int?,
      spotifyId: t['id'] as String?,
      source: 'spotify',
    );
  }

  List<Map<String, dynamic>> parseHistoryJson(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent);
      if (data is List) return data.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  Map<String, int> extractPlayCounts(
      List<Map<String, dynamic>> history) {
    final counts = <String, int>{};
    for (final entry in history) {
      final track = entry['trackName'] as String?;
      final artist = entry['artistName'] as String?;
      if (track == null || artist == null) continue;
      final key = '$artist::$track'.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}


class SpotifyService {
  static const _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const _redirectUri = 'nyxaudio://callback';
  static const _scopes =
      'user-library-read playlist-read-private user-read-private';

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<bool> get isAuthenticated async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');
    final expMs = prefs.getInt('spotify_token_expiry');
    if (_accessToken == null || expMs == null) return false;
    _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expMs);
    return _tokenExpiry!.isAfter(DateTime.now());
  }

  Future<void> launchAuth() async {
    final uri = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': _clientId,
      'response_type': 'token',
      'redirect_uri': _redirectUri,
      'scope': _scopes,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> saveToken(String token, int expiresIn) async {
    _accessToken = token;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: expiresIn));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_access_token', token);
    await prefs.setInt(
        'spotify_token_expiry', _tokenExpiry!.millisecondsSinceEpoch);
  }

  Future<void> logout() async {
    _accessToken = null;
    _tokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_token_expiry');
  }

  Future<Map<String, String>> _headers() async => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  Future<List<Track>> getLikedSongs(
      {void Function(int done, int total)? onProgress}) async {
    final tracks = <Track>[];
    String? url =
        'https://api.spotify.com/v1/me/tracks?limit=50&offset=0';
    int total = 0;

    while (url != null) {
      final res = await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      total = json['total'] as int? ?? 0;
      final items = (json['items'] as List?) ?? [];
      for (final item in items) {
        final t = (item as Map)['track'] as Map<String, dynamic>?;
        if (t == null) continue;
        tracks.add(_spotifyTrackToTrack(t));
      }
      onProgress?.call(tracks.length, total);
      url = json['next'] as String?;
    }
    return tracks;
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final playlists = <Map<String, dynamic>>[];
    String? url =
        'https://api.spotify.com/v1/me/playlists?limit=50&offset=0';
    while (url != null) {
      final res = await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      playlists.addAll(
          ((json['items'] as List?) ?? []).cast<Map<String, dynamic>>());
      url = json['next'] as String?;
    }
    return playlists;
  }

  Future<List<Track>> getPlaylistTracks(String playlistId,
      {void Function(int, int)? onProgress}) async {
    final tracks = <Track>[];
    String? url =
        'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=100';
    int total = 0;
    while (url != null) {
      final res = await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      total = json['total'] as int? ?? 0;
      final items = (json['items'] as List?) ?? [];
      for (final item in items) {
        final t = (item as Map)['track'] as Map<String, dynamic>?;
        if (t == null) continue;
        tracks.add(_spotifyTrackToTrack(t));
      }
      onProgress?.call(tracks.length, total);
      url = json['next'] as String?;
    }
    return tracks;
  }

  Track _spotifyTrackToTrack(Map<String, dynamic> t) {
    String? imageUrl;
    final album = t['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    if (images != null && images.isNotEmpty) {
      imageUrl = (images.first as Map)['url'] as String?;
    }
    final artists =
        ((t['artists'] as List?) ?? []).cast<Map<String, dynamic>>();
    final artistNames =
        artists.map((a) => a['name'] as String).join(', ');
    return Track(
      title: t['name'] as String? ?? '',
      artist: artistNames,
      album: album?['name'] as String?,
      albumArtUrl: imageUrl,
      durationMs: t['duration_ms'] as int?,
      spotifyId: t['id'] as String?,
      source: 'spotify',
    );
  }

  /// Import Spotify streaming history JSON file
  List<Map<String, dynamic>> parseHistoryJson(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Parse history from the extended streaming history format
  Map<String, int> extractPlayCounts(
      List<Map<String, dynamic>> history) {
    final counts = <String, int>{};
    for (final entry in history) {
      final track = entry['trackName'] as String?;
      final artist = entry['artistName'] as String?;
      if (track == null || artist == null) continue;
      final key = '$artist::$track'.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}
