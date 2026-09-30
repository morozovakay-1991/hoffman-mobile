import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/articles/index.dart';

import 'articles_harness.dart';

void main() {
  group('Article.fromJson', () {
    test('reads the backend ArticleResource', () {
      final article = Article.fromJson({
        ...articleJson(
          7,
          'Стресс',
          coverImageUrl: 'https://cdn.example.com/covers/7.jpg',
          isNew: true,
        ),
        'cover_image_path': 'covers/7.jpg',
      });

      expect(article.id, 7);
      expect(article.title, 'Стресс');
      expect(article.shortDescription, 'Описание: Стресс');
      expect(article.fullDescription, '<p>Полный текст: Стресс</p>');
      // The ready URL, never built from cover_image_path.
      expect(
        article.coverImageUrl,
        Uri.parse('https://cdn.example.com/covers/7.jpg'),
      );
      expect(article.publishedAt, DateTime.utc(2025, 3, 10, 9));
      expect(article.isNew, isTrue);
    });

    test('missing optional fields', () {
      final article = Article.fromJson(const {'id': 1});

      expect(article.title, isEmpty);
      expect(article.shortDescription, isEmpty);
      expect(article.fullDescription, isNull);
      expect(article.coverImageUrl, isNull);
      expect(article.publishedAt, isNull);
      expect(article.isNew, isFalse);
    });

    test('an empty cover URL is no cover', () {
      expect(
        Article.fromJson(articleJson(1, 'А', coverImageUrl: '')).coverImageUrl,
        isNull,
      );
    });
  });

  group('ArticleCatalog.fromJson', () {
    test('featured apart from the items', () {
      final catalog = ArticleCatalog.fromJson({
        'featured': articleJson(1, 'Заглавная'),
        'items': [articleJson(2, 'Вторая'), articleJson(3, 'Третья')],
      });

      expect(catalog.featured?.id, 1);
      expect(catalog.items.map((a) => a.id), [2, 3]);
      expect(catalog.isEmpty, isFalse);
    });

    test('no featured, no items: empty', () {
      expect(
        ArticleCatalog.fromJson(const {'featured': null, 'items': <Object>[]})
            .isEmpty,
        isTrue,
      );
    });

    test('a malformed body is an empty catalog', () {
      expect(ArticleCatalog.fromJson(null).isEmpty, isTrue);
      expect(ArticleCatalog.fromJson('oops').isEmpty, isTrue);
    });
  });
}
