// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 0;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      stock: fields[3] as int,
      description: fields[4] as String?,
      barcode: fields[6] as String,
      lowStockThreshold: fields[7] as int,
      category: fields[8] as String,
      size: fields[9] as String,
      weight: fields[10] as String,
      subCategory: fields[11] as String,
      imagePath: fields[12] as String?,
      color: (fields[13] as String?) ?? "N/A",
      brand: (fields[14] as String?) ?? "N/A",
      itemType: (fields[15] as String?) ?? "N/A",
      unit: (fields[16] as String?) ?? "Piece",
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.stock)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.barcode)
      ..writeByte(7)
      ..write(obj.lowStockThreshold)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.size)
      ..writeByte(10)
      ..write(obj.weight)
      ..writeByte(11)
      ..write(obj.subCategory)
      ..writeByte(12)
      ..write(obj.imagePath)
      ..writeByte(13)
      ..write(obj.color)
      ..writeByte(14)
      ..write(obj.brand)
      ..writeByte(15)
      ..write(obj.itemType)
      ..writeByte(16)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
