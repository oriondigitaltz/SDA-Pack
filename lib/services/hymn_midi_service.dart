import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import '../models/hymn.dart';

/// General MIDI soundfont used to render hymn MIDI playback.
const String _kSoundfontAsset = 'assets/soundfonts/default.sf2';

/// Plays a hymn's Standard MIDI File (Android only, per flutter_midi_pro),
/// resolved by convention at `assets/hymnals/<hymnalId>/midi/<numberLabel>.mid`.
///
/// Hymns without a bundled .mid (or hymnals without midi assets at all)
/// throw [HymnMidiUnavailableException], which callers should surface as a
/// friendly message.
class HymnMidiService {
  HymnMidiService._();
  static final HymnMidiService instance = HymnMidiService._();

  final MidiPro _midiPro = MidiPro();
  bool _initialized = false;
  int? _soundfontId;

  String assetPathFor(Hymn hymn) => 'assets/hymnals/${hymn.hymnalId}/midi/${hymn.numberLabel}.mid';

  Future<void> _ensureReady() async {
    if (!_initialized) {
      await _midiPro.init();
      _initialized = true;
    }
    _soundfontId ??= await _midiPro.loadSoundfontAsset(assetPath: _kSoundfontAsset, bank: 0, program: 0);
  }

  Future<void> play(Hymn hymn) async {
    try {
      await _ensureReady();
      await _midiPro.loadMidiAsset(assetPath: assetPathFor(hymn), sfId: _soundfontId!);
      await _midiPro.playMidi();
    } catch (e) {
      throw const HymnMidiUnavailableException();
    }
  }

  Future<void> stop() async {
    if (!_initialized) return;
    await _midiPro.stopMidi();
  }

  /// Cheap existence check so the UI can decide whether to attempt playback.
  Future<bool> isAvailable(Hymn hymn) async {
    try {
      await rootBundle.load(assetPathFor(hymn));
      return true;
    } catch (_) {
      return false;
    }
  }
}

class HymnMidiUnavailableException implements Exception {
  const HymnMidiUnavailableException();
}
