// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditRecordAdapter extends TypeAdapter<CreditRecord> {
  @override
  final int typeId = 3;

  @override
  CreditRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditRecord(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      amount: fields[3] as double,
      date: fields[4] as DateTime,
      type: fields[5] as String,
      isSettled: fields[6] as bool,
      description: fields[7] as String?,
      dueDate: fields[8] as DateTime?,
      paidAmount: fields[9] == null ? 0.0 : fields[9] as double,
      logs: (fields[10] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, CreditRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.isSettled)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.dueDate)
      ..writeByte(9)
      ..write(obj.paidAmount)
      ..writeByte(10)
      ..write(obj.logs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
