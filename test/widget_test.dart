import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab11_feed/main.dart';
import 'package:lab11_feed/models.dart';
import 'package:lab11_feed/repository.dart';

class FakeRepository extends PostRepository {
  FakeRepository({
    this.posts = const [
      Post(id: 1, title: 'Jollof rice', body: 'Spicy rice with chicken.'),
      Post(id: 2, title: 'Waakye', body: 'Rice and beans with shito.'),
    ],
    this.comments = const [
      Comment(id: 1, name: 'Ada', body: 'Looks delicious!'),
    ],
    this.countries = const [
      Country(
          name: 'Ghana',
          capital: 'Accra',
          currency: 'GH¢',
          population: '34.0 million',
          flag: '🇬🇭'),
      Country(
          name: 'Nigeria',
          capital: 'Abuja',
          currency: '₦',
          population: '223.8 million',
          flag: '🇳🇬'),
    ],
    this.fail = false,
    this.cached = const <Post>[],
  }) : super(client: MockClient((_) async => http.Response('[]', 200)));

  final List<Post> posts;
  final List<Comment> comments;
  final List<Country> countries;
  final bool fail;
  final List<Post> cached;

  @override
  Future<List<Post>> fetchPosts() async {
    if (fail) throw Exception('No internet');
    return posts;
  }

  @override
  Future<List<Post>> fetchCachedPosts() async => cached;

  @override
  Future<List<Comment>> fetchComments(int postId) async => comments;

  @override
  Future<List<Country>> fetchCountries() async => countries;

  @override
  Future<Post> createPost(String title) async =>
      Post(id: 101, title: title, body: 'From UMaT');
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpFeed(WidgetTester tester, {required FakeRepository repo}) async {
    await tester.pumpWidget(MaterialApp(home: FeedPage(repository: repo)));
    await tester.pumpAndSettle();
  }

  testWidgets('data state shows posts and the FAB', (tester) async {
    await pumpFeed(tester, repo: FakeRepository());
    expect(find.text('Jollof rice'), findsOneWidget);
    expect(find.text('Waakye'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('exercise 1: search filters posts by title', (tester) async {
    await pumpFeed(tester, repo: FakeRepository());

    await tester.enterText(find.byType(TextField).first, 'waak');
    await tester.pumpAndSettle();

    expect(find.text('Waakye'), findsOneWidget);
    expect(find.text('Jollof rice'), findsNothing);
  });

  testWidgets('exercise 2: tapping a post opens its comments', (tester) async {
    await pumpFeed(tester, repo: FakeRepository());

    await tester.tap(find.text('Jollof rice'));
    await tester.pumpAndSettle();

    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Looks delicious!'), findsOneWidget);
  });

  testWidgets('error state shows Retry when there is no cache', (tester) async {
    await pumpFeed(tester, repo: FakeRepository(fail: true));

    expect(find.text('Could not load posts. Check your data.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('exercise 3: offline banner with cached posts', (tester) async {
    await pumpFeed(
      tester,
      repo: FakeRepository(
        fail: true,
        cached: const [Post(id: 9, title: 'Cached jollof', body: 'Saved earlier')],
      ),
    );

    expect(find.text('Offline — showing cached posts'), findsOneWidget);
    expect(find.text('Cached jollof'), findsOneWidget);
  });

  testWidgets('created post snackbar shows the server id', (tester) async {
    await pumpFeed(tester, repo: FakeRepository());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'New post');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('Created post 101'), findsOneWidget);
  });

  testWidgets('exercise 5: country explorer highlights Ghana', (tester) async {
    await pumpFeed(tester, repo: FakeRepository());

    await tester.tap(find.byTooltip('Country explorer'));
    await tester.pumpAndSettle();

    expect(find.text('Country Explorer'), findsOneWidget);
    expect(find.textContaining('Spotlight: Ghana'), findsOneWidget);
    expect(find.textContaining('Capital: Accra'), findsOneWidget);
    expect(find.textContaining('Currency: GH¢'), findsOneWidget);
    expect(find.textContaining('Population: 34.0 million'), findsOneWidget);
  });
}
