// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymn.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HymnAdapter extends TypeAdapter<Hymn> {
  @override
  final int typeId = 0;

  @override
  Hymn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hymn(
      hymnalId: fields[0] as String,
      number: fields[1] as int,
      title: fields[2] as String,
      blockTexts: (fields[3] as List).cast<String>(),
      blockIsChorus: (fields[4] as List).cast<bool>(),
      suffix: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Hymn obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.hymnalId)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.blockTexts)
      ..writeByte(4)
      ..write(obj.blockIsChorus)
      ..writeByte(5)
      ..write(obj.suffix);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HymnAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
