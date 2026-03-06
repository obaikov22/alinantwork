import 'package:hive/hive.dart';

part 'note_record.g.dart';

@HiveType(typeId: 3)
enum NoteType {
  @HiveField(0)
  general,

  @HiveField(1)
  employee,
}

@HiveType(typeId: 4)
class NoteRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late NoteType type;

  @HiveField(3)
  late String text;

  @HiveField(4)
  String? employeeId;

  @HiveField(5)
  late DateTime createdAt;

  NoteRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.text,
    this.employeeId,
    required this.createdAt,
  });

  NoteRecord copyWith({
    String? id,
    DateTime? date,
    NoteType? type,
    String? text,
    String? employeeId,
    DateTime? createdAt,
  }) {
    return NoteRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      text: text ?? this.text,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
