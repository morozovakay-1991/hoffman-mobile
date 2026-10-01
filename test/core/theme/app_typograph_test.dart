import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';

void main() {
  group('bindShortWords', () {
    test('nbsp is U+00A0', () {
      expect(nbsp.codeUnits, [0x00A0]);
    });

    for (final (input, expected) in [
      ('проживания и восстановления', 'проживания и$nbspвосстановления'),
      ('путь к себе', 'путь к$nbspсебе'),
      ('работа в группе', 'работа в$nbspгруппе'),
      ('встреча с собой', 'встреча с$nbspсобой'),
      ('мысли о прошлом', 'мысли о$nbspпрошлом'),
      ('я, а не он', 'я, а$nbspне он'),
      ('В начале пути', 'В$nbspначале пути'),
    ]) {
      test('"$input": the one-letter word sticks to the next one', () {
        expect(bindShortWords(input), expected);
      });
    }

    test('a chain of one-letter words is tied as a whole', () {
      expect(
        bindShortWords('и в доме, и с собой'),
        'и$nbspв$nbspдоме, и$nbspс$nbspсобой',
      );
    });

    test('after an opening quote or bracket', () {
      expect(bindShortWords('«В пути» (о себе)'), '«В$nbspпути» (о$nbspсебе)');
    });

    test('several spaces collapse into one nbsp', () {
      expect(bindShortWords('дом с  садом'), 'дом с$nbspсадом');
    });

    test('line breaks and longer words are left alone', () {
      expect(bindShortWords('мысли о\nпрошлом'), 'мысли о\nпрошлом');
      expect(bindShortWords('на пути до дома'), 'на пути до дома');
      expect(bindShortWords('в конце и'), 'в$nbspконце и');
    });

    test('a letter inside a word is not a word', () {
      expect(bindShortWords('класс в доме'), 'класс в$nbspдоме');
      expect(bindShortWords('25 минут'), '25 минут');
    });

    test('empty text', () {
      expect(bindShortWords(''), '');
    });
  });
}
