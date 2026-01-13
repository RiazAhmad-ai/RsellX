// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'damage_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DamageRecordAdapter extends TypeAdapter<DamageRecord> {
  @override
  final int typeId = 4;

  @override
  DamageRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DamageRecord(
      id: fields[0] as String,
      itemId: fields[1] as String,
      itemName: fields[2] as String,
      qty: fields[3] as int,
      lossAmount: fields[4] as double,
      date: fields[5] as DateTime,
      reason: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DamageRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.qty)
      ..writeByte(4)
      ..write(obj.lossAmount)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DamageRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
