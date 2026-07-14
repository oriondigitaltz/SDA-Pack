# Devotion Feed

`devotions_feed.json` is the online daily-devotion feed the app pulls from.
It is a JSON map keyed by full date (`yyyy-MM-dd`):

```json
{
  "2026-07-14": {
    "title_en": "Walking in God's Light",
    "title_sw": "Kutembea katika Nuru ya Mungu",
    "verse_ref": "Psalms 119:105",
    "body_en": "…",
    "body_sw": "…",
    "category": "Light"
  }
}
```

- `verse_ref` must match the bundled Bible book titles (e.g. `Psalms 23:1`,
  `1 Corinthians 13:4-7`).
- `category` is optional — it becomes the colored chip on the home screen's
  Recent Devotions cards (e.g. `Love`, `Peace`, `Faith`).
- Future-dated entries are ignored by the app until their day arrives, so you
  can publish a whole month/quarter ahead safely.
- Every entry the app downloads (dated today or earlier) is stored on the
  device permanently as a **past study**, even after you rotate old entries
  out of this file.

## How to host it (GitHub, free)

1. Create a public GitHub repository, e.g. `sifahymns-feed`.
2. Upload `devotions_feed.json` to the repository root.
3. Your feed URL is:
   `https://raw.githubusercontent.com/<your-username>/sifahymns-feed/main/devotions_feed.json`
4. Put that URL in `kDevotionFeedUrl` inside
   [lib/services/devotion_feed_service.dart](../lib/services/devotion_feed_service.dart).
5. To publish new devotions, just edit the file on GitHub — the app picks the
   changes up next time it launches with internet.

Any other static host (Firebase Hosting, S3, your own server) works the same
way — the app only needs a URL that returns this JSON.

The seed file in this folder was generated from the app's bundled devotions
for 1 Jul – 31 Dec 2026, with auto-derived categories. Replace or edit
entries freely; the format above is all that matters.
