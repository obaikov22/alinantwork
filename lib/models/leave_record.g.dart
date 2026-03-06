// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeaveRecordAdapter extends TypeAdapter<LeaveRecord> {
  @override
  final int typeId = 2;

  @override
  LeaveRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaveRecord(
      id: fields[0] as String,
      employeeId: fields[1] as String,
      type: fields[2] as LeaveType,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LeaveRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.employeeId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LeaveTypeAdapter extends TypeAdapter<LeaveType> {
  @override
  final int typeId = 1;

  @override
  LeaveType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LeaveType.annual;
      case 1:
        return LeaveType.sick;
      case 2:
        return LeaveType.birthdayHoliday;
      case 3:
        return LeaveType.bankHoliday;
      default:
        return LeaveType.annual;
    }
  }

  @override
  void write(BinaryWriter writer, LeaveType obj) {
    switch (obj) {
      case LeaveType.annual:
        writer.writeByte(0);
        break;
      case LeaveType.sick:
        writer.writeByte(1);
        break;
      case LeaveType.birthdayHoliday:
        writer.writeByte(2);
        break;
      case LeaveType.bankHoliday:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
