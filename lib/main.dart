import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';

void main() => runApp(const FeedApp());

class FeedApp extends StatelessWidget {
  const FeedApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'UMaT News Feed',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const FeedPage(),
      );
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.repository});

  /// Injectable so tests and golden screenshots can use fake data.
  final PostRepository? repository;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final PostRepository _repo = widget.repository ?? PostRepository();
  late Future<List<Post>> _future;
  final _search = TextEditingController();
  String _query = '';
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Post>> _load() async {
    if (mounted) setState(() => _offline = false);
    try {
      return await _repo.fetchPosts();
    } catch (_) {
      // Exercise 3: fall back to the last successful response.
      final cached = await _repo.fetchCachedPosts();
      if (cached.isNotEmpty) {
        if (mounted) setState(() => _offline = true);
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next.catchError((_) => <Post>[]);
  }

  Future<void> _newPost() async {
    final ctrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New post'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Post title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    String msg;
    try {
      final post = await _repo.createPost(title);
      msg = 'Created post ${post.id}';
    } catch (_) {
      msg = 'Could not create post. Try again.';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('UMaT News Feed'),
          actions: [
            IconButton(
              tooltip: 'Country explorer',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CountriesPage(repository: _repo),
                ),
              ),
              icon: const Icon(Icons.public),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'New post',
          onPressed: _newPost,
          child: const Icon(Icons.add),
        ),
        body: Column(children: [
          // Exercise 1: search above the list.
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Search posts',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (_offline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Offline — showing cached posts',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.brown),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Post>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Could not load posts. Check your data.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ]),
                  );
                }

                final posts = (snap.data ?? const <Post>[])
                    .where((p) => p.title.toLowerCase().contains(_query))
                    .toList();
                if (posts.isEmpty) {
                  return Center(
                    child: Text(_query.isEmpty
                        ? 'No posts yet'
                        : 'No posts match "$_query"'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (_, i) {
                      final post = posts[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${post.id}')),
                        title: Text(post.title),
                        subtitle: Text(post.body,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailsPage(
                              post: post,
                              repository: _repo,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      );
}

/// Exercise 2: post details with comments from /posts/{id}/comments.
class PostDetailsPage extends StatelessWidget {
  const PostDetailsPage({
    super.key,
    required this.post,
    required this.repository,
  });

  final Post post;
  final PostRepository repository;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Post ${post.id}')),
        body: FutureBuilder<List<Comment>>(
          future: repository.fetchComments(post.id),
          builder: (context, snap) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(post.body),
              const Divider(height: 32),
              if (snap.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (snap.hasError)
                Text('Could not load comments: ${snap.error}')
              else
                for (final c in snap.data ?? const <Comment>[])
                  ListTile(
                    leading: CircleAvatar(child: Text('${c.id}')),
                    title: Text(c.name),
                    subtitle: Text(c.body),
                  ),
            ],
          ),
        ),
      );
}

/// Exercise 5: country explorer powered by restcountries.com.
class CountriesPage extends StatefulWidget {
  const CountriesPage({super.key, required this.repository});

  final PostRepository repository;

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  late final Future<List<Country>> _future = widget.repository.fetchCountries();
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Country Explorer')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                labelText: 'Search countries',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Country>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final countries = snap.data ?? const <Country>[];

                // Ghana is highlighted at the top (exercise 5).
                final ghana = countries.where((c) =>
                    c.name.toLowerCase() == 'ghana' ||
                    c.name.toLowerCase().contains('ghana')).firstOrNull;

                final shown = countries
                    .where((c) => c.name.toLowerCase().contains(_query))
                    .toList();

                return ListView(children: [
                  if (ghana != null)
                    Card(
                      color: Colors.amber.shade100,
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🇬🇭 Spotlight: ${ghana.name}',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text('Capital: ${ghana.capital}'),
                            Text('Currency: ${ghana.currency}'),
                            Text('Population: ${ghana.population}'),
                          ],
                        ),
                      ),
                    ),
                  for (final c in shown)
                    ListTile(
                      leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
                      title: Text(c.name),
                      subtitle: Text(
                          '${c.capital} • ${c.currency} • ${c.population}'),
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}
