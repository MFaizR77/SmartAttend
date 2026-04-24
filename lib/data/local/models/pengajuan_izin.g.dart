// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pengajuan_izin.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PengajuanIzinAdapter extends TypeAdapter<PengajuanIzin> {
  @override
  final int typeId = 2;

  @override
  PengajuanIzin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PengajuanIzin(
      id: fields[0] as String?,
      clientUuid: fields[1] as String,
      mahasiswaId: fields[2] as String,
      sesiId: fields[3] as String,
      jenis: fields[4] as String,
      keterangan: fields[5] as String,
      fotoPath: fields[6] as String?,
      fotoUrl: fields[7] as String?,
      statusApproval: fields[8] as String,
      catatanDosen: fields[9] as String?,
      disetujuiOleh: fields[10] as String?,
      disetujuiPada: fields[11] as DateTime?,
      syncStatus: fields[12] as String,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PengajuanIzin obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientUuid)
      ..writeByte(2)
      ..write(obj.mahasiswaId)
      ..writeByte(3)
      ..write(obj.sesiId)
      ..writeByte(4)
      ..write(obj.jenis)
      ..writeByte(5)
      ..write(obj.keterangan)
      ..writeByte(6)
      ..write(obj.fotoPath)
      ..writeByte(7)
      ..write(obj.fotoUrl)
      ..writeByte(8)
      ..write(obj.statusApproval)
      ..writeByte(9)
      ..write(obj.catatanDosen)
      ..writeByte(10)
      ..write(obj.disetujuiOleh)
      ..writeByte(11)
      ..write(obj.disetujuiPada)
      ..writeByte(12)
      ..write(obj.syncStatus)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PengajuanIzinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
