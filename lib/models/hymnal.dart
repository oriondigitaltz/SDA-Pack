class Hymnal {
  final String id;
  final String displayName;
  final String nativeName;
  final String assetPath;
  final bool available;

  const Hymnal({
    required this.id,
    required this.displayName,
    required this.nativeName,
    required this.assetPath,
    required this.available,
  });

  String get indexAssetPath => '$assetPath/index.json';

  String assetPathFor(String filename) => '$assetPath/$filename';
}

const List<Hymnal> hymnalRegistry = [
  Hymnal(
    id: 'en',
    displayName: 'Church Hymnal',
    nativeName: 'Church Hymnal',
    assetPath: 'assets/hymnals/en',
    available: true,
  ),
  Hymnal(
    id: 'sw',
    displayName: 'Nyimbo za Kristo',
    nativeName: 'Nyimbo za Kristo',
    assetPath: 'assets/hymnals/sw',
    available: true,
  ),
];
