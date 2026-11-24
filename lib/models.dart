class Post {
  const Post({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};
}

class Comment {
  const Comment({required this.id, required this.name, required this.body});

  final int id;
  final String name;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

class Country {
  const Country({
    required this.name,
    required this.capital,
    required this.currency,
    required this.population,
    required this.flag,
  });

  final String name;
  final String capital;
  final String currency;
  final String population;
  final String flag;

  static String _capital(Map<String, dynamic> json) {
    final list = json['capital'] as List<dynamic>?;
    return (list?.isNotEmpty ?? false) ? list!.first as String : '—';
  }

  static String _currency(Map<String, dynamic> json) {
    final currencies = json['currencies'] as Map<String, dynamic>?;
    if (currencies == null || currencies.isEmpty) return '—';
    final first = currencies.values.first as Map<String, dynamic>;
    return first['symbol'] as String? ?? first['name'] as String? ?? '—';
  }

  static String _population(Map<String, dynamic> json) {
    final value = json['population'] as int? ?? 0;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} million';
    }
    return value.toString();
  }

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        name: json['name'] is Map<String, dynamic>
            ? (json['name'] as Map<String, dynamic>)['common'] as String? ?? ''
            : json['name'] as String? ?? '',
        capital: _capital(json),
        currency: _currency(json),
        population: _population(json),
        flag: json['flags'] is Map<String, dynamic>
            ? (json['flags'] as Map<String, dynamic>)['emoji'] as String? ?? ''
            : '',
      );
}
