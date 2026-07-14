import 'package:flutter_test/flutter_test.dart';
import 'package:sifahymns/data/markdown_hymn_parser.dart';

void main() {
  test('parses a hymn with a chorus', () {
    const raw = '''
## Watchman Blow The Gospel Trumpet.

Watchman, blow the gospel trumpet,
Evry soul a warning give;

CHORUS
Blow the trumpet, trusty watchman,
Blow it loud o'er land and sea.

Sound it loud o'er ev'ry hilltop,
Gloomy shade, and sunny plain;''';

    final hymn = MarkdownHymnParser.parse(hymnalId: 'en', fallbackNumber: 1, raw: raw);

    expect(hymn.title, 'Watchman Blow The Gospel Trumpet.');
    expect(hymn.number, 1);
    expect(hymn.numberLabel, '1');
    expect(hymn.blocks.length, 3);
    expect(hymn.blocks[0].isChorus, isFalse);
    expect(hymn.blocks[1].isChorus, isTrue);
    expect(hymn.blocks[1].text, contains('Blow the trumpet'));
    expect(hymn.blocks[2].isChorus, isFalse);
  });

  test('parses a hymn with no chorus', () {
    const raw = '''
## Holy, Holy, Holy

Holy, holy, holy! Lord God Almighty!
Early in the morning our song shall rise to thee.

Holy, holy, holy! All the saints adore thee,
casting down their golden crowns around the glassy sea;''';

    final hymn = MarkdownHymnParser.parse(hymnalId: 'en', fallbackNumber: 200, raw: raw);

    expect(hymn.title, 'Holy, Holy, Holy');
    expect(hymn.blocks.length, 2);
    expect(hymn.blocks.every((b) => !b.isChorus), isTrue);
  });

  test('trims trailing whitespace on lines', () {
    const raw = '## Title \n\nLine one \nLine two  \n';
    final hymn = MarkdownHymnParser.parse(hymnalId: 'en', fallbackNumber: 5, raw: raw);

    expect(hymn.title, 'Title');
    expect(hymn.blocks.single.text, 'Line one\nLine two');
  });

  test('handles lowercase Chorus label', () {
    const raw = '## Title\n\nVerse one line.\n\nChorus\nChorus line one\nChorus line two\n';
    final hymn = MarkdownHymnParser.parse(hymnalId: 'en', fallbackNumber: 10, raw: raw);

    expect(hymn.blocks[1].isChorus, isTrue);
    expect(hymn.blocks[1].text, 'Chorus line one\nChorus line two');
  });

  test('parses plain-text Swahili hymn with number-title header and metadata lines', () {
    const raw = '﻿010-Kristo Wa Neema Yote \n'
        'Come Thou Fount (SDAH334)\n'
        'Doh ni E♭\n'
        '\n'
        'Kristo wa neema yote imbisha moyo wangu\n'
        'Mifulizo ya baraka inaamsha shangwe kuu.\n'
        '\n'
        '   CHORUS\n'
        '   Nitakwenda niwatafute wapotevu wageuke,\n'
        '   Waingie katika zizi la Mwokozi Yesu Kristo.\n';

    final hymn = MarkdownHymnParser.parse(hymnalId: 'sw', fallbackNumber: 999, raw: raw);

    expect(hymn.number, 10);
    expect(hymn.suffix, '');
    expect(hymn.numberLabel, '10');
    expect(hymn.title, 'Kristo Wa Neema Yote');
    expect(hymn.blocks.length, 2);
    expect(hymn.blocks[0].isChorus, isFalse);
    expect(hymn.blocks[1].isChorus, isTrue);
    expect(hymn.blocks[1].text, contains('Nitakwenda'));
  });

  test('parses alternate-tune variant suffix like 026a', () {
    const raw = '026a-Tupe Amani\n'
        'God The Omnipotent (SDAH84)\n'
        'Doh ni D\n'
        '\n'
        'Mungu mtukufu Aliyeumba pepo kuvuma Na radi kali;\n';

    final hymn = MarkdownHymnParser.parse(hymnalId: 'sw', fallbackNumber: 999, raw: raw);

    expect(hymn.number, 26);
    expect(hymn.suffix, 'a');
    expect(hymn.numberLabel, '26a');
    expect(hymn.title, 'Tupe Amani');
  });

  test('parses plain-text header with only one metadata line', () {
    const raw = '131a-Kwa Mahitaji Ya Kesho\n'
        "Lord For Tomorrow And It's Needs\n"
        '\n'
        'Kwa mahitaji ya kesho, Sina ombi;\n';

    final hymn = MarkdownHymnParser.parse(hymnalId: 'sw', fallbackNumber: 999, raw: raw);

    expect(hymn.numberLabel, '131a');
    expect(hymn.title, 'Kwa Mahitaji Ya Kesho');
    expect(hymn.blocks.single.text, 'Kwa mahitaji ya kesho, Sina ombi;');
  });
}
