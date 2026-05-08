import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class LastFmService {
  static const _apiKey = 'YOUR_LASTFM_API_KEY'; // replace with real key
  static const _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  Future<List<LastFmTrack>> search(String query, {int limit = 20}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'method': 'track.search',
      'track': query,
      'api_key': _apiKey,
      'format': 'json',
      'limit': '$limit',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final matches =
        (json['results']?['trackmatches']?['track'] as List?) ?? [];
    return matches
        .map((t) => LastFmTrack.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<List<LastFmTrack>> getSimilarArtistTracks(String artist,
      {int limit = 10}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'method': 'artist.gettoptracks',
      'artist': artist,
      'api_key': _apiKey,
      'format': 'json',
      'limit': '$limit',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final tracks = (json['toptracks']?['track'] as List?) ?? [];
    return tracks
        .map((t) => LastFmTrack.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getSimilarArtists(String artist,
      {int limit = 6}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'method': 'artist.getsimilar',
      'artist': artist,
      'api_key': _apiKey,
      'format': 'json',
      'limit': '$limit',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final similar =
        (json['similarartists']?['artist'] as List?) ?? [];
    return similar
        .map((a) => (a as Map<String, dynamic>)['name'] as String)
        .toList();
  }

  Future<LastFmTrack?> getTrackInfo(String track, String artist) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'method': 'track.getInfo',
      'track': track,
      'artist': artist,
      'api_key': _apiKey,
      'format': 'json',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final t = json['track'] as Map<String, dynamic>?;
    if (t == null) return null;
    return LastFmTrack.fromJson(t);
  }
}
