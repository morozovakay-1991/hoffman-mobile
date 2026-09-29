import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/meditations/index.dart';

import 'meditations_harness.dart';

const _cover = 'https://api.example.com/storage/covers/m.jpg';

Map<String, dynamic> _data(Object? body) =>
    (body! as Map<String, Object?>)['data']! as Map<String, dynamic>;

void main() {
  group('MeditationCatalog.fromJson', () {
    test('parses {featured, items}', () {
      final catalog = MeditationCatalog.fromJson(
        _data(
          catalogResponse(
            meditationJson(1, 'Утренняя', coverImageUrl: _cover),
            [
              meditationJson(2, 'Вечерняя', durationSeconds: 600),
              meditationJson(3, 'Закрытая', isLocked: true),
            ],
          ).body,
        ),
      );

      final featured = catalog.featured!;
      expect(featured.id, 1);
      expect(featured.title, 'Утренняя');
      expect(featured.shortDescription, 'Описание: Утренняя');
      expect(featured.coverImageUrl, Uri.parse(_cover));
      expect(featured.durationSeconds, 1500);
      expect(featured.isLocked, isFalse);
      expect(catalog.items.map((m) => m.id), [2, 3]);
      expect(catalog.items.first.durationSeconds, 600);
      expect(catalog.items.last.isLocked, isTrue);
      expect(catalog.items.last.fullDescription, isNull);
      expect(catalog.isEmpty, isFalse);
    });

    test('without featured: only items', () {
      final catalog = MeditationCatalog.fromJson(
        _data(catalogResponse(null, [meditationJson(2, 'Вечерняя')]).body),
      );

      expect(catalog.featured, isNull);
      expect(catalog.items.single.id, 2);
      expect(catalog.isEmpty, isFalse);
    });

    test('a missing or malformed body is an empty catalog', () {
      expect(MeditationCatalog.fromJson(null).isEmpty, isTrue);
      expect(MeditationCatalog.fromJson(const {'items': 'x'}).isEmpty, isTrue);
      expect(
        MeditationCatalog.fromJson(const {
          'featured': null,
          'items': <Object>[],
        }).isEmpty,
        isTrue,
      );
    });
  });

  group('Meditation.fromJson', () {
    test('reads the detail fields; no cover is null', () {
      final meditation = Meditation.fromJson(
        _data(detailResponse(meditationJson(1, 'Утренняя')).body),
      );

      expect(meditation.fullDescription, '<p>Полное описание практики</p>');
      expect(meditation.topicIds, [3, 5]);
      expect(meditation.isFree, isFalse);
      expect(meditation.coverImageUrl, isNull);
    });
  });

  group('MeditationAudio', () {
    test('parses the presigned URL and its expiry', () {
      final audio = MeditationAudio.fromJson(
        _data(audioResponse('https://s3.example.com/1.mp3?sig=a').body),
      );

      expect(audio.url, Uri.parse('https://s3.example.com/1.mp3?sig=a'));
      expect(audio.expiresAt, testNow.add(const Duration(hours: 1)));
    });

    test('counts as expired a minute before expires_at', () {
      final audio = MeditationAudio(
        url: Uri.parse('https://s3.example.com/1.mp3'),
        expiresAt: testNow,
      );

      expect(
        audio.isExpiredAt(testNow.subtract(const Duration(minutes: 2))),
        isFalse,
      );
      expect(
        audio.isExpiredAt(testNow.subtract(const Duration(seconds: 59))),
        isTrue,
      );
      expect(audio.isExpiredAt(testNow.add(const Duration(hours: 1))), isTrue);
    });
  });
}
