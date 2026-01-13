// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleRecordAdapter extends TypeAdapter<SaleRecord> {
  @override
  final int typeId = 1;

  @override
  SaleRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleRecord(
      id: fields[0] as String,
      itemId: fields[1] as String,
      name: fields[2] as String,
      price: fields[3] as double,
      actualPrice: fields[4] as double,
      qty: fields[5] as int,
      profit: fields[6] as double,
      date: fields[7] as DateTime,
      status: fields[8] as String,
      billId: fields[9] as String?,
      category: fields[10] == null ? "General" : fields[10] as String,
      size: fields[11] == null ? "N/A" : fields[11] as String,
      weight: fields[12] == null ? "N/A" : fields[12] as String,
      subCategory: fields[13] == null ? "N/A" : fields[13] as String,
      imagePath: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleRecord obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.actualPrice)
      ..writeByte(5)
      ..write(obj.qty)
      ..writeByte(6)
      ..write(obj.profit)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.billId)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.size)
      ..writeByte(12)
      ..write(obj.weight)
      ..writeByte(13)
      ..write(obj.subCategory)
      ..writeByte(14)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
