import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/home/index.dart';

import 'home_harness.dart';

const _cover = 'https://api.example.com/storage/covers/x.jpg';

void main() {
  group('HomeSummary.fromJson', () {
    test('parses every section as {featured, items} and the diary '
        'progress', () {
      final body = homeResponse().body! as Map<String, Object?>;
      final summary = HomeSummary.fromJson(
        body['data']! as Map<String, dynamic>,
      );

      expect(summary.meditations.featured?.id, 1);
      expect(summary.meditations.items.map((m) => m.id), [2]);
      expect(summary.meditations.featured?.durationSeconds, 1500);
      expect(summary.tools.featured?.stageTag, 'выражение');
      expect(summary.tools.items.map((t) => t.id), [12]);
      expect(summary.topics.featured?.id, 21);
      expect(
        summary.topics.items.single.fullDescription,
        'Текст темы: Границы',
      );
      expect(summary.articles.featured?.id, 31);
      expect(
        summary.articles.featured?.publishedAt,
        DateTime.utc(2025, 3, 10, 9),
      );
      expect(summary.articles.items.map((a) => a.id), [32]);
      expect(summary.diary.isAvailable, isTrue);
      expect(summary.diary.currentDay, 25);
      expect(summary.diary.totalDays, 100);
    });

    test('missing sections are empty, a missing diary is closed', () {
      final summary = HomeSummary.fromJson(const {});

      for (final section in [
        summary.meditations,
        summary.tools,
        summary.topics,
        summary.articles,
      ]) {
        expect(section.featured, isNull);
        expect(section.items, isEmpty);
        expect(section.isEmpty, isTrue);
      }
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

    test('a section without a featured item keeps its items', () {
      final section = HomeSection.fromJson(
        sectionJson(null, [meditationJson(1, 'Первая')]),
        HomeMeditation.fromJson,
      );

      expect(section.featured, isNull);
      expect(section.items.single.id, 1);
      expect(section.isEmpty, isFalse);
      expect(
        HomeSection.fromJson(
          sectionJson(meditationJson(2, 'Заглавная')),
          HomeMeditation.fromJson,
        ).isEmpty,
        isFalse,
      );
    });

    test('a section in the old flat form is read as empty', () {
      final summary = HomeSummary.fromJson({
        'meditations': [meditationJson(1, 'Медитация')],
      });

      expect(summary.meditations.isEmpty, isTrue);
    });

    test('every item takes its cover_image_url as is', () {
      final url = Uri.parse(_cover);

      expect(
        HomeMeditation.fromJson(
          meditationJson(1, 'Медитация', coverImageUrl: _cover),
        ).coverImageUrl,
        url,
      );
      expect(
        HomeTool.fromJson(toolJson(2, 'Инструмент', coverImageUrl: _cover))
            .coverImageUrl,
        url,
      );
      expect(
        HomeTopic.fromJson(topicJson(3, 'Тема', coverImageUrl: _cover))
            .coverImageUrl,
        url,
      );
      expect(
        HomeArticle.fromJson(articleJson(4, 'Статья', coverImageUrl: _cover))
            .coverImageUrl,
        url,
      );
    });

    test('no or an empty cover_image_url means no cover', () {
      expect(
        HomeMeditation.fromJson(meditationJson(1, 'Медитация')).coverImageUrl,
        isNull,
      );
      expect(
        HomeTool.fromJson(toolJson(2, 'Инструмент')).coverImageUrl,
        isNull,
      );
      expect(
        HomeTopic.fromJson({...topicJson(3, 'Тема'), 'cover_image_url': ''})
            .coverImageUrl,
        isNull,
      );
      expect(
        HomeArticle.fromJson(articleJson(4, 'Статья', publishedAt: null))
            .coverImageUrl,
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
