import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'data/beliefs_repository.dart';
import 'data/bible_repository.dart';
import 'data/collections_repository.dart';
import 'data/devotion_repository.dart';
import 'data/favorites_repository.dart';
import 'data/hymn_repository.dart';
import 'data/notes_repository.dart';
import 'data/study_guide_repository.dart';
import 'models/collection.dart';
import 'models/hymn.dart';
import 'providers/content_providers.dart';
import 'providers/hymnal_providers.dart';
import 'providers/study_guide_providers.dart';
import 'services/devotion_feed_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Hive.initFlutter();
  Hive.registerAdapter(HymnAdapter());
  Hive.registerAdapter(CollectionAdapter());

  final hymnRepository = await HymnRepository.open();
  final legacyFavorites = await FavoritesRepository.open();
  final collectionsRepository = await CollectionsRepository.open(legacyFavorites: legacyFavorites);
  final notesRepository = await NotesRepository.open();
  final bibleRepository = await BibleRepository.open();
  final devotionRepository = await DevotionRepository.open();
  final beliefsRepository = await BeliefsRepository.open();
  final studyGuideRepository = await StudyGuideRepository.open();

  await notificationService.init();
  // Re-assert the reminder on every launch so it survives
  // app updates and missed boot broadcasts.
  if (devotionRepository.reminderEnabled) {
    await notificationService.scheduleWeekly(
      hour: devotionRepository.reminderHour,
      minute: devotionRepository.reminderMinute,
      weekdays: devotionRepository.reminderDays,
    );
  }

  final container = ProviderContainer(
    overrides: [
      hymnRepositoryProvider.overrideWithValue(hymnRepository),
      collectionsRepositoryProvider.overrideWithValue(collectionsRepository),
      notesRepositoryProvider.overrideWithValue(notesRepository),
      bibleRepositoryProvider.overrideWithValue(bibleRepository),
      devotionRepositoryProvider.overrideWithValue(devotionRepository),
      beliefsRepositoryProvider.overrideWithValue(beliefsRepository),
      studyGuideRepositoryProvider.overrideWithValue(studyGuideRepository),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SdaPackApp(),
    ),
  );

  // Pull today's devotion from the online feed in the background; new
  // entries land in the past-studies cache and refresh the home screen.
  unawaited(
    DevotionFeedService(devotionRepository).refresh().then((added) {
      if (added > 0) {
        container.read(devotionCacheVersionProvider.notifier).state++;
      }
    }),
  );
}
