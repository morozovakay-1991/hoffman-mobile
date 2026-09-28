import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/home/index.dart';

import 'home_harness.dart';

final Uri _storage = Uri.parse('https://api.example.com/storage/');

void main() {
  group('HomeSummary.fromJson', () {
    test('parses every section and the diary progress', () {
      final body = homeResponse().body! as Map<String, Object?>;
      final summary = HomeSummary.fromJson(
        body['data']! as Map<String, dynamic>,
        storageBaseUrl: _storage,
      );

      expect(summary.meditations.map((m) => m.id), [1, 2]);
      expect(summary.meditations.first.durationSeconds, 1500);
      expect(summary.tools.first.stageTag, 'выражение');
      expect(summary.topics.last.fullDescription, 'Текст темы: Границы');
      expect(summary.articles.first.publishedAt, DateTime.utc(2025, 3, 10, 9));
      expect(summary.diary.isAvailable, isTrue);
      expect(summary.diary.currentDay, 25);
      expect(summary.diary.totalDays, 100);
    });

    test('missing sections are empty, a missing diary is closed', () {
      final summary = HomeSummary.fromJson(const {}, storageBaseUrl: _storage);

      expect(summary.meditations, isEmpty);
      expect(summary.tools, isEmpty);
      expect(summary.topics, isEmpty);
      expect(summary.articles, isEmpty);
      expect(summary.diary.isAvailable, isFalse);
      expect(summary.diary.progress, 0);
    });

    test('locked items keep the flag; a locked topic has no text', () {
      final topic = HomeTopic.fromJson(topicJson(1, 'Тема', isLocked: true));
      final tool = HomeTool.fromJson(
        toolJson(2, 'Инструмент', stageTag: null, isLocked: true),
      );

      expect(topic.isLocked, isTrue);
      expect(topic.fullDescription, isNull);
      expect(tool.isLocked, isTrue);
      expect(tool.stageTag, isNull);
    });

    test('article cover paths resolve against the storage URL', () {
      final article = HomeArticle.fromJson({
        ...articleJson(1, 'Статья'),
        'cover_image_path': 'articles/cover.jpg',
      }, storageBaseUrl: _storage);

      expect(
        article.coverUrl,
        Uri.parse('https://api.example.com/storage/articles/cover.jpg'),
      );
      expect(
        HomeArticle.fromJson(
          articleJson(2, 'Без обложки', publishedAt: null),
          storageBaseUrl: _storage,
        ).coverUrl,
        isNull,
      );
    });
  });

  group('DiaryProgress.progress', () {
    test('share of the diary reached, capped at 1', () {
      expect(DiaryProgress.fromJson(diaryJson(currentDay: 1)).progress, 0.01);
      expect(DiaryProgress.fromJson(diaryJson(currentDay: 100)).progress, 1);
      expect(
        const DiaryProgress(
          isAvailable: true,
          totalDays: 100,
          currentDay: 140,
        ).progress,
        1,
      );
    });

    test('a closed diary shows no progress, whatever the day', () {
      expect(
        const DiaryProgress(
          isAvailable: false,
          totalDays: 100,
          currentDay: 25,
        ).progress,
        0,
      );
    });
  });

  group('HomeText', () {
    test('greeting falls back to no name', () {
      expect(HomeText.greetingFor('Алексей'), 'С возвращением, Алексей');
      expect(HomeText.greetingFor('  '), 'С возвращением');
    });

    test('duration in whole minutes with Russian plurals', () {
      expect(HomeText.duration(1500), '25 минут');
      expect(HomeText.duration(60), '1 минута');
      expect(HomeText.duration(20), '1 минута');
      expect(HomeText.duration(180), '3 минуты');
      expect(HomeText.duration(11 * 60), '11 минут');
      expect(HomeText.duration(21 * 60), '21 минута');
      expect(HomeText.duration(0), '0 минут');
    });

    test('month and year like the mockup', () {
      expect(HomeText.monthYear(DateTime(2025, 3, 10)), 'Март, 2025');
      expect(HomeText.monthYear(null), '');
    });
  });
}
