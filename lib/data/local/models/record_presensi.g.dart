// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_presensi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordPresensiAdapter extends TypeAdapter<RecordPresensi> {
  @override
  final int typeId = 0;

  @override
  RecordPresensi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordPresensi(
      id: fields[0] as String?,
      clientUuid: fields[1] as String,
      sesiId: fields[2] as String,
      mahasiswaId: fields[3] as String,
      timestamp: fields[4] as DateTime,
      statusHadir: fields[5] as bool,
      metode: fields[6] as String,
      syncStatus: fields[7] as String,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RecordPresensi obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientUuid)
      ..writeByte(2)
      ..write(obj.sesiId)
      ..writeByte(3)
      ..write(obj.mahasiswaId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.statusHadir)
      ..writeByte(6)
      ..write(obj.metode)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordPresensiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
