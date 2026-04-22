// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sesi_absensi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SesiAbsensiAdapter extends TypeAdapter<SesiAbsensi> {
  @override
  final int typeId = 1;

  @override
  SesiAbsensi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SesiAbsensi(
      id: fields[0] as String?,
      sesiId: fields[1] as String,
      jadwalId: fields[2] as String,
      tanggal: fields[3] as DateTime,
      status: fields[4] as String,
      dibukaOleh: fields[5] as String?,
      openedAt: fields[6] as DateTime?,
      closedAt: fields[7] as DateTime?,
      syncStatus: fields[8] as String,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SesiAbsensi obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sesiId)
      ..writeByte(2)
      ..write(obj.jadwalId)
      ..writeByte(3)
      ..write(obj.tanggal)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.dibukaOleh)
      ..writeByte(6)
      ..write(obj.openedAt)
      ..writeByte(7)
      ..write(obj.closedAt)
      ..writeByte(8)
      ..write(obj.syncStatus)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SesiAbsensiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
