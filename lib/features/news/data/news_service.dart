import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/news_model.dart';

class NewsService {
  static const _geminiApiKey = 'AIzaSyA76EiMgXRB2Sb2yumt4P6iVM-OrRtNNJc';
  static const _cacheKey = 'news_cache';
  static const _cacheTimeKey = 'news_cache_time';
  static const _cacheDuration = Duration(hours: 1);

  static const _feeds = [
    _RssFeed('https://www.gsmarena.com/rss-news-reviews.php3', 'GSMArena'),
    _RssFeed('https://www.androidauthority.com/feed/', 'Android Authority'),
    _RssFeed('https://9to5google.com/feed/', '9to5Google'),
  ];

  Future<List<NewsArticle>> fetchNews({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _getCache();
      if (cached != null) return cached;
    }

    final articles = <NewsArticle>[];

    for (final feed in _feeds) {
      try {
        final feedArticles = await _parseFeed(feed);
        articles.addAll(feedArticles);
      } catch (e) {
        debugPrint('RSS fetch error (${feed.source}): $e');
      }
    }

    if (articles.isEmpty) {
      final cached = await _getCache(ignoreExpiry: true);
      return cached ?? [];
    }

    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final top = articles.take(20).toList();

    final translated = await _translateBatch(top);

    await _saveCache(translated);
    return translated;
  }

  Future<List<NewsArticle>> _parseFeed(_RssFeed feed) async {
    final response = await http.get(
      Uri.parse(feed.url),
      headers: {'User-Agent': 'Oxyn/1.3.0'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final body = response.body;
    final items = <NewsArticle>[];

    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final matches = itemRegex.allMatches(body);

    for (final match in matches.take(10)) {
      final itemXml = match.group(1) ?? '';

      final title = _extractTag(itemXml, 'title');
      final link = _extractTag(itemXml, 'link');
      final desc = _extractTag(itemXml, 'description');
      final pubDate = _extractTag(itemXml, 'pubDate');

      if (title.isEmpty || link.isEmpty) continue;

      DateTime? date;
      if (pubDate.isNotEmpty) {
        date = _parseDate(pubDate);
      }

      final cleanDesc = _stripHtml(desc);

      items.add(NewsArticle(
        title: _stripCdata(title),
        description: cleanDesc.length > 200
            ? '${cleanDesc.substring(0, 200)}...'
            : cleanDesc,
        url: link.trim(),
        source: feed.source,
        publishedAt: date ?? DateTime.now(),
      ));
    }

    return items;
  }

  String _extractTag(String xml, String tag) {
    final regex = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }

  String _stripCdata(String text) {
    return text
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>'), '')
        .trim();
  }

  String _stripHtml(String html) {
    return _stripCdata(html)
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.tryParse(dateStr) ?? _parseRfc822(dateStr);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseRfc822(String dateStr) {
    try {
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final parts = dateStr.split(' ');
      if (parts.length < 5) return null;
      final day = int.parse(parts[1]);
      final month = months[parts[2]] ?? 1;
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  Future<List<NewsArticle>> _translateBatch(List<NewsArticle> articles) async {
    if (articles.isEmpty) return articles;

    final result = <NewsArticle>[];
    const batchSize = 5;

    for (var start = 0; start < articles.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, articles.length);
      final batch = articles.sublist(start, end);
      final translated = await _translateChunk(batch);
      result.addAll(translated);
    }

    return result;
  }

  Future<List<NewsArticle>> _translateChunk(List<NewsArticle> chunk) async {
    try {
      final buffer = StringBuffer();
      for (var i = 0; i < chunk.length; i++) {
        buffer.writeln('[${i + 1}] ${chunk[i].title}');
        buffer.writeln('[${i + 1}] ${chunk[i].description}');
        if (i < chunk.length - 1) buffer.writeln();
      }

      final prompt =
          'Aşağıdaki akıllı telefon haberlerini Türkçe\'ye çevir.\n'
          'Her haberin numarası var [1], [2] gibi. Aynı formatı koru.\n'
          'Her haber için ilk satır başlık, ikinci satır açıklama.\n'
          'SADECE çeviriyi yaz, başka hiçbir şey ekleme.\n\n'
          '${buffer.toString()}';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 2000},
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint('Translation API error: ${response.statusCode}');
        return chunk;
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return chunk;

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return chunk;

      final translatedText = (parts[0]['text'] as String).trim();

      final result = <NewsArticle>[];
      for (var i = 0; i < chunk.length; i++) {
        final num = i + 1;
        final titleRegex = RegExp('\\[$num\\]\\s*(.+)');
        final matches = titleRegex.allMatches(translatedText).toList();

        if (matches.length >= 2) {
          result.add(NewsArticle(
            title: matches[0].group(1)?.trim() ?? chunk[i].title,
            description: matches[1].group(1)?.trim() ?? chunk[i].description,
            url: chunk[i].url,
            source: chunk[i].source,
            publishedAt: chunk[i].publishedAt,
            imageUrl: chunk[i].imageUrl,
          ));
        } else {
          result.add(chunk[i]);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Translation chunk error: $e');
      return chunk;
    }
  }

  Future<List<NewsArticle>?> _getCache({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimeKey);
      if (cacheTime == null) return null;

      if (!ignoreExpiry) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (elapsed > _cacheDuration.inMilliseconds) return null;
      }

      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;

      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Cache read error: $e');
      return null;
    }
  }

  Future<void> _saveCache(List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(articles.map((a) => a.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }
}

class _RssFeed {
  final String url;
  final String source;
  const _RssFeed(this.url, this.source);
}
