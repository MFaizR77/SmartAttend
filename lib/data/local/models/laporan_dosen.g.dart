// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laporan_dosen.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LaporanDosenAdapter extends TypeAdapter<LaporanDosen> {
  @override
  final int typeId = 3;

  @override
  LaporanDosen read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LaporanDosen(
      id: fields[0] as String?,
      jadwalId: fields[1] as String,
      dosenId: fields[2] as String,
      materi: fields[3] as String?,
      waktuMulai: fields[4] as DateTime,
      waktuSelesai: fields[5] as DateTime?,
      syncStatus: fields[6] as String,
      tanggal: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LaporanDosen obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.jadwalId)
      ..writeByte(2)
      ..write(obj.dosenId)
      ..writeByte(3)
      ..write(obj.materi)
      ..writeByte(4)
      ..write(obj.waktuMulai)
      ..writeByte(5)
      ..write(obj.waktuSelesai)
      ..writeByte(6)
      ..write(obj.syncStatus)
      ..writeByte(7)
      ..write(obj.tanggal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaporanDosenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
