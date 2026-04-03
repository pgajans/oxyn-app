import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/news_service.dart';
import 'news_model.dart';

final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

final newsProvider =
    AsyncNotifierProvider<NewsNotifier, List<NewsArticle>>(NewsNotifier.new);

class NewsNotifier extends AsyncNotifier<List<NewsArticle>> {
  @override
  Future<List<NewsArticle>> build() async {
    final service = ref.read(newsServiceProvider);
    return service.fetchNews();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final service = ref.read(newsServiceProvider);
      return service.fetchNews(forceRefresh: true);
    });
  }
}
