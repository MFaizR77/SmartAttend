// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jadwal_kuliah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JadwalKuliahAdapter extends TypeAdapter<JadwalKuliah> {
  @override
  final int typeId = 4;

  @override
  JadwalKuliah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JadwalKuliah(
      id: fields[0] as String,
      kodeMK: fields[1] as String,
      namaMK: fields[2] as String,
      kelas: fields[3] as String,
      program: fields[4] as String,
      hari: fields[5] as String,
      jamMulai: fields[6] as String,
      jamSelesai: fields[7] as String,
      tipe: fields[8] as String,
      ruangan: fields[9] as String,
      dosenIds: (fields[10] as List).cast<String>(),
      namaDosen: fields[11] as String,
      periodeAkademikKode: fields[12] as String?,
      isActive: fields[13] as bool,
      cachedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, JadwalKuliah obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kodeMK)
      ..writeByte(2)
      ..write(obj.namaMK)
      ..writeByte(3)
      ..write(obj.kelas)
      ..writeByte(4)
      ..write(obj.program)
      ..writeByte(5)
      ..write(obj.hari)
      ..writeByte(6)
      ..write(obj.jamMulai)
      ..writeByte(7)
      ..write(obj.jamSelesai)
      ..writeByte(8)
      ..write(obj.tipe)
      ..writeByte(9)
      ..write(obj.ruangan)
      ..writeByte(10)
      ..write(obj.dosenIds)
      ..writeByte(11)
      ..write(obj.namaDosen)
      ..writeByte(12)
      ..write(obj.periodeAkademikKode)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalKuliahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
