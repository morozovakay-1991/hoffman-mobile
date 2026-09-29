import '../../helpers/app_harness.dart';

const me = 'GET /api/v1/auth/me';
const verificationStatus = 'GET /api/v1/verification/status';
const getHome = 'GET /api/v1/home';

Map<String, Object?> meditationJson(
  int id,
  String title, {
  int durationSeconds = 1500,
  String? coverImageUrl,
  bool isLocked = false,
}) => {
  'id': id,
  'title': title,
  'short_description': 'Описание: $title',
  'full_description': isLocked ? null : 'Полный текст',
  'audio_path': isLocked ? null : 'meditations/$id.mp3',
  'duration_seconds': durationSeconds,
  'is_free': false,
  'is_locked': isLocked,
  'cover_image_url': coverImageUrl,
};

Map<String, Object?> toolJson(
  int id,
  String title, {
  String? stageTag = 'выражение',
  String? coverImageUrl,
  bool isLocked = false,
}) => {
  'id': id,
  'title': title,
  'short_description': 'Описание: $title',
  'full_description': isLocked ? null : 'Полный текст',
  'is_locked': isLocked,
  'stage_tag': stageTag,
  'cover_image_url': coverImageUrl,
};

Map<String, Object?> topicJson(
  int id,
  String title, {
  String? coverImageUrl,
  bool isLocked = false,
}) => {
  'id': id,
  'title': title,
  'subtitle': 'Подзаголовок: $title',
  'full_description': isLocked ? null : 'Текст темы: $title',
  'is_locked': isLocked,
  'cover_image_url': coverImageUrl,
};

Map<String, Object?> articleJson(
  int id,
  String title, {
  String? publishedAt = '2025-03-10T09:00:00.000000Z',
  String? coverImageUrl,
}) => {
  'id': id,
  'title': title,
  'short_description': 'Описание: $title',
  'full_description': 'Полный текст',
  'cover_image_url': coverImageUrl,
  'published_at': publishedAt,
  'is_new': false,
  'is_locked': false,
};

Map<String, Object?> diaryJson({int? currentDay = 25, bool available = true}) =>
    {
      'current_day': available ? currentDay : null,
      'total_days': 100,
      'is_available': available,
    };

/// A content section of `GET /home`: [featured] (or none) and the other
/// [items].
Map<String, Object?> sectionJson(
  Map<String, Object?>? featured, [
  List<Map<String, Object?>> items = const [],
]) => {'featured': featured, 'items': items};

/// Backend `GET /home`; by default each section has a featured item and one
/// more.
FakeResponse homeResponse({
  Map<String, Object?>? meditations,
  Map<String, Object?>? tools,
  Map<String, Object?>? topics,
  Map<String, Object?>? articles,
  Map<String, Object?>? diary,
  Duration delay = Duration.zero,
}) {
  return FakeResponse(
    200,
    {
      'data': {
        'meditations':
            meditations ??
            sectionJson(meditationJson(1, 'Утренняя медитация'), [
              meditationJson(2, 'Visioning – образ будущего'),
            ]),
        'tools':
            tools ??
            sectionJson(toolJson(11, 'Распознавание паттернов'), [
              toolJson(12, 'Выражение гнева'),
            ]),
        'topics':
            topics ??
            sectionJson(topicJson(21, 'Я жертва'), [topicJson(22, 'Границы')]),
        'articles':
            articles ??
            sectionJson(articleJson(31, 'Что такое Процесс Хоффмана?'), [
              articleJson(32, '«Навсегда твой» или про роли в семье'),
            ]),
        'diary_progress': diary ?? diaryJson(),
      },
    },
    const {},
    delay,
  );
}

/// Backend `VerificationRequestResource`, or no request at all.
FakeResponse verification(String? status) => FakeResponse(200, {
  'verification_request': status == null
      ? null
      : {
          'id': 1,
          'status': status,
          'last_name': 'Иванова',
          'first_name': 'Анна',
          'phone': '+79990000000',
        },
});

/// A signed-in user (`Kate`) who lands on home.
TestEnvironment homeEnv([Map<String, FakeResponse> routes = const {}]) {
  return TestEnvironment(
    token: 'token',
    backend: FakeBackend({
      me: const FakeResponse(200, {'user': testUserJson}),
      verificationStatus: verification(null),
      getHome: homeResponse(),
      ...routes,
    }),
  );
}
