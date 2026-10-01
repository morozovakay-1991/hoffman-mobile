/// No-break space (U+00A0).
const String nbsp = ' ';

/// A one-letter word (`и`, `в`, `к`, `с`, `о`, `а`, `у`, `я`…) at the start
/// of the text or after a space, an opening bracket or quote, followed by
/// spaces.
final RegExp _shortWord = RegExp(
  '(?<=^|[\\s$nbsp(«„“"])([А-Яа-яЁёA-Za-z]) +',
  unicode: true,
);

/// [text] with every one-letter preposition or conjunction tied to the next
/// word by a [nbsp], so it never hangs alone at the end of a line
/// ("и", "в", "к", "с", "о"…). Line breaks are kept.
String bindShortWords(String text) =>
    text.replaceAllMapped(_shortWord, (m) => '${m[1]}$nbsp');
