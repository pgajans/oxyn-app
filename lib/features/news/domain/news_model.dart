class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String source;
  final DateTime publishedAt;
  final String? imageUrl;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'url': url,
        'source': source,
        'publishedAt': publishedAt.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        title: json['title'] as String,
        description: json['description'] as String,
        url: json['url'] as String,
        source: json['source'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        imageUrl: json['imageUrl'] as String?,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}s önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${publishedAt.day}.${publishedAt.month}.${publishedAt.year}';
  }
}
