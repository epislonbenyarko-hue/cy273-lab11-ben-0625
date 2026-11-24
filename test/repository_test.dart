import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab11_feed/repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<PostRepository> repoFor(MockClient client) async {
    return PostRepository(
      client: client,
      sharedPreferences: await SharedPreferences.getInstance(),
    );
  }

  test('fetchPosts parses the API and caches the result', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode([
            {'id': 1, 'title': 'Jollof', 'body': 'Spicy rice'},
          ]),
          200,
        ));
    final repo = await repoFor(client);

    final posts = await repo.fetchPosts();
    expect(posts.single.title, 'Jollof');
    expect((await repo.fetchCachedPosts()).single.id, 1);
  });

  test('fetchPosts throws on a non-200 response', () async {
    final client = MockClient((_) async => http.Response('oops', 500));
    final repo = await repoFor(client);
    expect(repo.fetchPosts, throwsException);
  });

  test('createPost sends JSON and parses the 201 reply', () async {
    String? body;
    final client = MockClient((request) async {
      body = request.body;
      return http.Response(
        jsonEncode({'id': 101, 'title': 'New', 'body': 'From UMaT', 'userId': 1}),
        201,
      );
    });
    final repo = await repoFor(client);

    final post = await repo.createPost('New');
    expect(post.id, 101);
    expect(jsonDecode(body!)['title'], 'New');
  });

  test('fetchComments parses /posts/id/comments', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/posts/3/comments');
      return http.Response(
        jsonEncode([
          {'id': 1, 'name': 'Ada', 'body': 'Nice'},
        ]),
        200,
      );
    });
    final repo = await repoFor(client);

    final comments = await repo.fetchComments(3);
    expect(comments.single.name, 'Ada');
  });

  test('fetchCountries finds Ghana with capital, currency and population',
      () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode([
            {
              'name': {'common': 'Ghana'},
              'capital': ['Accra'],
              'currencies': {'GHS': {'name': 'Ghanaian cedi', 'symbol': 'GHS'}},
              'population': 34000000,
              'flags': {'emoji': 'GH'},
            },
          ]),
          200,
        ));
    final repo = await repoFor(client);

    final countries = await repo.fetchCountries();
    expect(countries.single.name, 'Ghana');
    expect(countries.single.capital, 'Accra');
    expect(countries.single.currency, 'GHS');
    expect(countries.single.population, '34.0 million');
  });
}
