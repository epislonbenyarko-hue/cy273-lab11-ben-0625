import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class PostRepository {
  PostRepository({http.Client? client, SharedPreferences? sharedPreferences})
      : _client = client ?? http.Client(),
        _prefs = sharedPreferences;

  static const _host = 'jsonplaceholder.typicode.com';
  static const _countriesHost = 'restcountries.com';
  static const _cacheKey = 'cached_posts';
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
  final SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences =>
      _prefs != null ? Future.value(_prefs) : SharedPreferences.getInstance();

  Future<List<Post>> fetchPosts() async {
    final res = await _client
        .get(Uri.https(_host, '/posts'), headers: {'Accept': 'application/json'})
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    final posts = list
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    await _cachePosts(posts);
    return posts;
  }

  Future<void> _cachePosts(List<Post> posts) async {
    final prefs = await _preferences;
    await prefs.setString(
      _cacheKey,
      jsonEncode(posts.map((p) => p.toJson()).toList()),
    );
  }

  /// Exercise 3: the last successful response, used when the network fails.
  Future<List<Post>> fetchCachedPosts() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const <Post>[];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Post> createPost(String title) async {
    final res = await _client
        .post(
          Uri.https(_host, '/posts'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'title': title, 'body': 'From UMaT', 'userId': 1}),
        )
        .timeout(_timeout);
    if (res.statusCode != 201) {
      throw Exception('Error ${res.statusCode}');
    }
    return Post.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Exercise 2: comments for one post.
  Future<List<Comment>> fetchComments(int postId) async {
    final res = await _client
        .get(Uri.https(_host, '/posts/$postId/comments'))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Exercise 5: countries from restcountries.com.
  Future<List<Country>> fetchCountries() async {
    final uri = Uri.https(_countriesHost, '/v3.1/all', {
      'fields': 'name,capital,currencies,population,flags,cca3',
    });
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    final countries = list
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return countries;
  }
}
