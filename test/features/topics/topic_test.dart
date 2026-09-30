import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/index.dart';

void main() {
  group('Topic.fromJson', () {
    test('reads every field, the links and the optional extras', () {
      final topic = Topic.fromJson(const {
        'id': 21,
        'title': 'Я жертва',
        'subtitle': 'нелюбовь к себе / нет ресурсов / выгорание',
        'short_description': '  Коротко  ',
        'full_description': '<p>Полный текст</p>',
        'possible_work': ['Первое', 'Второе'],
        'cover_image_url': 'https://api.example.com/c.jpg',
        'is_locked': false,
        'tool_ids': [12, 11],
        'meditation_ids': [2],
      });

      expect(topic.id, 21);
      expect(topic.title, 'Я жертва');
      expect(topic.subtitle, 'нелюбовь к себе / нет ресурсов / выгорание');
      expect(topic.shortDescription, 'Коротко');
      expect(topic.fullDescription, '<p>Полный текст</p>');
      expect(topic.possibleWork, '<ul><li>Первое</li><li>Второе</li></ul>');
      expect(topic.coverImageUrl, Uri.parse('https://api.example.com/c.jpg'));
      expect(topic.toolIds, [12, 11]);
      expect(topic.meditationIds, [2]);
    });

    test('the backend TopicResource as it is today: no short description, '
        'no possible work, no links on a list item', () {
      final topic = Topic.fromJson(const {
        'id': 22,
        'title': 'Границы',
        'subtitle': 'границы',
        'full_description': null,
        'cover_image_url': null,
        'is_locked': true,
      });

      expect(topic.shortDescription, isNull);
      expect(topic.possibleWork, isNull);
      expect(topic.coverImageUrl, isNull);
      expect(topic.isLocked, isTrue);
      expect(topic.toolIds, isEmpty);
      expect(topic.meditationIds, isEmpty);
      expect(topic.summary, isEmpty);
    });
  });

  group('Topic.possibleWorkHtml', () {
    test('HTML is kept as is (numbered lists stay numbered)', () {
      expect(
        Topic.possibleWorkHtml(' <ol><li>Первое</li></ol> '),
        '<ol><li>Первое</li></ol>',
      );
    });

    test('plain text: one escaped item per non-empty line', () {
      expect(
        Topic.possibleWorkHtml('Первое\n\n  Второе & третье  '),
        '<ul><li>Первое</li><li>Второе &amp; третье</li></ul>',
      );
    });

    test('nothing to show is null', () {
      expect(Topic.possibleWorkHtml(null), isNull);
      expect(Topic.possibleWorkHtml(''), isNull);
      expect(Topic.possibleWorkHtml(const <Object>[]), isNull);
      expect(Topic.possibleWorkHtml(const ['  ']), isNull);
      expect(Topic.possibleWorkHtml(42), isNull);
    });
  });

  group('Topic.summary', () {
    Topic withDescription(String html) =>
        Topic(id: 1, title: 't', subtitle: 's', fullDescription: html);

    test('plain text of the full description, one line per paragraph', () {
      expect(
        withDescription('<p>Раз &amp; <b>два</b></p><p>Три<br>четыре</p>')
            .summary,
        'Раз & два\nТри\nчетыре',
      );
    });

    test('a long description is cut at a word with an ellipsis', () {
      final summary = withDescription('слово ' * 200).summary;
      expect(summary.length, lessThanOrEqualTo(Topic.summaryMaxLength + 1));
      expect(summary, endsWith('слово…'));
    });
  });

  group('catalogs', () {
    test('a malformed body is an empty catalog', () {
      expect(TopicCatalog.fromJson(null).isEmpty, isTrue);
      expect(ToolCatalog.fromJson('oops').isEmpty, isTrue);
    });

    test('ToolCatalog.all puts the featured tool first', () {
      final catalog = ToolCatalog.fromJson(const {
        'featured': {'id': 11, 'title': 'A'},
        'items': [
          {'id': 12, 'title': 'B', 'stage_tag': '  '},
        ],
      });
      expect(catalog.all.map((t) => t.id), [11, 12]);
      // A blank stage has no badge.
      expect(catalog.items.single.stageTag, isNull);
    });
  });
}
