import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/services/text_sharer.dart';

import '../../helpers/app_harness.dart';
import '../home/home_harness.dart';

export '../home/home_harness.dart'
    show meditationJson, sectionJson, toolJson, topicJson;

const getTools = 'GET /api/v1/tools';
String getTool(int id) => 'GET /api/v1/tools/$id';
const getTopics = 'GET /api/v1/topics';
String getTopic(int id) => 'GET /api/v1/topics/$id';
const getMeditationsList = 'GET /api/v1/meditations';

/// `GET /tools`, `GET /topics` or `GET /meditations`: [featured] (or none)
/// and the other [items].
FakeResponse catalog(
  Map<String, Object?>? featured, [
  List<Map<String, Object?>> items = const [],
]) => FakeResponse(200, {'data': sectionJson(featured, items)});

/// `GET /tools/{id}` of an open tool.
FakeResponse toolDetail(Map<String, Object?> tool) => FakeResponse(200, {
  'data': {
    ...tool,
    'full_description': '<p>Полное описание упражнения</p>',
    'topic_ids': [21],
  },
});

/// `GET /topics/{id}` of an open topic, with its extra fields.
FakeResponse topicDetail(
  Map<String, Object?> topic, {
  Object? possibleWork = const [
    'Распознавание паттернов: что именно произошло?',
    'Выход в состояние взрослого',
  ],
  List<int> toolIds = const [],
  List<int> meditationIds = const [],
}) => FakeResponse(200, {
  'data': {
    ...topic,
    'full_description': '<p>Полное описание темы</p>',
    'possible_work': possibleWork,
    'tool_ids': toolIds,
    'meditation_ids': meditationIds,
  },
});

/// Every tool, topic and meditation of [ToolsHarness.subscribed].
final Map<String, FakeResponse> subscribedRoutes = {
  getTools: catalog(toolJson(11, 'Распознавание паттернов'), [
    toolJson(12, 'Выражение гнева'),
    toolJson(13, 'Письмо себе', stageTag: null),
  ]),
  getTool(11): toolDetail(toolJson(11, 'Распознавание паттернов')),
  getTool(12): toolDetail(toolJson(12, 'Выражение гнева')),
  getTopics: catalog(topicJson(21, 'Я жертва'), [
    topicJson(22, 'Границы'),
    topicJson(23, 'Тревога'),
  ]),
  getTopic(21): topicDetail(
    topicJson(21, 'Я жертва'),
    toolIds: [12, 11],
    meditationIds: [2],
  ),
  getTopic(22): topicDetail(topicJson(22, 'Границы')),
  getMeditationsList: catalog(meditationJson(1, 'Утренняя медитация'), [
    meditationJson(2, 'Медитация сочувствия себе'),
  ]),
};

/// A signed-in user with the tools and topics backend; [shared] collects
/// what the share sheet got.
class ToolsHarness {
  ToolsHarness(Map<String, FakeResponse> routes) {
    env = TestEnvironment(
      token: 'token',
      backend: FakeBackend({
        me: const FakeResponse(200, {'user': testUserJson}),
        verificationStatus: verification(null),
        getHome: homeResponse(),
        ...routes,
      }),
      extraOverrides: [
        textSharerProvider.overrideWithValue((text, {subject, origin}) async {
          shared.add((text: text, subject: subject));
        }),
      ],
    );
  }

  /// With an active subscription: everything open.
  ToolsHarness.subscribed([Map<String, FakeResponse> routes = const {}])
    : this({...subscribedRoutes, ...routes});

  late final TestEnvironment env;
  final List<({String text, String? subject})> shared = [];

  FakeBackend get backend => env.backend;

  /// Launches the app (on home) and opens [location]: switches to it when
  /// it is a tab, pushes it otherwise.
  Future<ProviderContainer> open(WidgetTester tester, String location) async {
    final container = await pumpApp(tester, env);
    final router = container.read(appRouterProvider);
    if (AppTab.of(location) != null) {
      router.go(location);
    } else {
      unawaited(router.push(location));
    }
    await tester.pumpAndSettle();
    return container;
  }
}
