# SDA Pack (SifaHymns)

A Seventh-day Adventist companion app for Android and iOS, built with Flutter.
It bundles the Bible, hymnals, daily devotions, Sabbath School study guides,
and the 28 Fundamental Beliefs — in **English and Kiswahili** — and works
offline, with online extras when internet is available.

Developed by **Orion Digital Tanzania**.

## Features

- **Bible** — full Bible in English and Kiswahili (bundled SQLite database),
  readable and searchable completely offline.
- **Bible Songs** — the Church Hymnal (English) and Nyimbo za Kristo
  (Kiswahili), with search, favorites, collections, and personal notes.
- **Daily Devotions** — a bilingual devotion for every day of the year.
  When online, the app pulls fresh devotions from a remote JSON feed
  (see [feed/README.md](feed/README.md)); every fetched devotion is stored
  on the device permanently as a **Past Study**, with category tags and
  favorites. Offline, the bundled devotions are used.
- **Bible Study Guides** — official Sabbath School quarterly lessons in
  Kiswahili and English, fetched from the Adventech Sabbath School API.
  Quarterlies → weekly lessons → daily readings; everything opened is
  cached for offline reading.
- **Devotion Calendar** — month view showing which days you have read or
  saved a devotion; tap any day to open it.
- **Reading streaks & reminders** — mark devotions as read, keep a streak,
  and get a local notification at your chosen time on the weekdays you pick.
- **SDA Beliefs** — interactive guide to the 28 Fundamental Beliefs with
  scripture references linked to the bundled Bible.
- **My Favorites & Collections** — save hymns and devotions into lists.
- **Light & dark theme** — warm cream/orange design, Kiswahili-first.

## Project layout

| Path | What it is |
|---|---|
| `lib/screens/` | UI screens (home, devotion, calendar, settings, study guides, Bible, hymns, beliefs) |
| `lib/data/` | Repositories: Bible (sqflite), hymns, devotions, study guides, collections (Hive) |
| `lib/services/` | Devotion feed fetcher, local notifications |
| `lib/providers/` | Riverpod state (content, hymnal, study guides) |
| `assets/` | Bundled Bible DB, hymnals, devotions, beliefs, branding (SVG logos) |
| `feed/` | Devotion feed seed file + hosting instructions |

## Online sources

- **Devotion feed**: URL configured as `kDevotionFeedUrl` in
  [lib/services/devotion_feed_service.dart](lib/services/devotion_feed_service.dart).
  Host `feed/devotions_feed.json` anywhere (e.g. GitHub raw) and point the
  constant at it — format details in [feed/README.md](feed/README.md).
- **Study guides**: `https://sabbath-school.adventech.io/api/v2/{lang}/quarterlies/…`
  (languages `en` and `sw`).

## Building

```bash
flutter pub get
flutter run                 # debug on a connected device
flutter build apk --release # release APK
```

Regenerate launcher icons after changing the logo:

```bash
flutter pub run flutter_launcher_icons
```

Run checks:

```bash
flutter analyze
flutter test
```
