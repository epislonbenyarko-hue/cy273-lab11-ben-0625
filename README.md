# CY 273 — Lab 11: Campus News Feed from a REST API

| | |
|---|---|
| **Name** | Richard G. Benyarkoh |
| **Index No.** | FCM.41.018.062.025 |
| **Course** | CY 273 — Mobile Application Development (UMaT) |
| **Lab** | 11 — Campus News Feed from a REST API |
| **Target** | Chrome / web (also Android if the Android folder is added) |

## What this app does

Fetches posts from `jsonplaceholder.typicode.com` through a repository class,
shows loading / data / empty / error states, supports search, pull-to-refresh,
creating a post, post details with comments, offline caching with an offline
banner, and a country explorer built on `restcountries.com` that highlights
Ghana.

## Features completed

### Starter code
- [x] `Post` model with `fromJson`
- [x] `PostRepository.fetchPosts()` and `createPost()` with 10 s timeout
- [x] `authStateChanges`-style `FutureBuilder` states (loading, error, empty, data)
- [x] `RefreshIndicator` pull-to-refresh and **Retry** button
- [x] `+` FAB → New post dialog → `Created post 101` SnackBar

### Exercises
1. **Search** — a `TextField` above the list filters loaded posts by title as you type, with a clear button.
2. **Post details** — tapping a post opens `PostDetailsPage`, which loads comments from `/posts/{id}/comments`.
3. **Offline cache** — successful responses are saved to `shared_preferences`; if a refresh fails, cached posts are shown with an **Offline — showing cached posts** banner.
4. **Repository unit tests** — `PostRepository` takes an injectable `http.Client`; `MockClient` tests cover GET, non-200 errors, POST body/201 reply, comments and countries.
5. **Country explorer** — an AppBar action opens a `restcountries.com` explorer; Ghana is pinned in a highlighted card with capital (Accra), currency (GH¢) and population.

## Android permission

If you add the Android platform, put this above `<application>` in
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Chrome/web needs no manifest entry.

## Project layout

```text
lab11_feed/
├── lib/
│   ├── main.dart        # FeedApp, FeedPage, PostDetailsPage, CountriesPage
│   ├── models.dart      # Post, Comment, Country (+ parsers)
│   └── repository.dart  # PostRepository with injectable http.Client + cache
├── test/
│   ├── repository_test.dart  # 5 MockClient unit tests
│   └── widget_test.dart      # 7 widget tests
├── screenshots/         # loading, data, error, created-post SnackBar
├── pubspec.yaml
└── README.md
```

## How to run

```powershell
cd lab11_feed
flutter pub get
flutter run -d chrome
```

Try this in the app:

1. Wait for the list to load, then pull down to refresh.
2. Type `waak` in the search box — only matching titles remain.
3. Tap a post to see its comments.
4. Turn off Wi-Fi/data and refresh — the cached list and Offline banner appear.
5. Tap **+**, enter a title, tap **Post** — the SnackBar says `Created post 101`.
6. Tap the globe icon in the AppBar to open the country explorer.

## Tests

```powershell
flutter analyze     # No issues found
flutter test        # 12 tests, all passing
```

- 5 repository unit tests using `MockClient`
- 7 widget tests: data state, search, details/comments, error+Retry, offline banner, created-post SnackBar, Ghana spotlight

## Screenshots

`screenshots/` contains:

- `01_loading.png`
- `02_data.png`
- `03_error.png`
- `04_created_snackbar.png`

These are Flutter golden images rendered from deterministic fake repository
data, so they are stable and do not depend on network availability.

## Reflection questions

1. **What was the most difficult part of this lab, and how did you solve it?**
   Making the offline state testable was the hardest part. I let the
   `FutureBuilder` call a `_load()` helper that first tries the network and, on
   failure, falls back to `fetchCachedPosts()` and sets an `_offline` flag. I
   then injected a fake repository into `FeedPage` so both the failure and the
   cached-data paths could be tested without touching real Wi-Fi.

2. **Name one widget, function or concept you used today and explain what it
   does in your own words.**
   **`MockClient`**: a fake HTTP client from `package:http/testing.dart`. You
   give it a callback that returns a canned `Response`, then pass it into the
   repository constructor. That lets me test status-code handling and JSON
   parsing exactly, without hitting the real API or needing an internet
   connection.
