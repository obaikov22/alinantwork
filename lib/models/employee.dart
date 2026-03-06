import 'package:hive/hive.dart';

part 'employee.g.dart';

@HiveType(typeId: 0)
class Employee extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime birthday;

  @HiveField(3)
  int totalAnnualDays;

  @HiveField(4)
  int usedAnnualDays;

  @HiveField(5)
  late int color;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  String? role;

  Employee({
    required this.id,
    required this.name,
    required this.birthday,
    this.totalAnnualDays = 28,
    this.usedAnnualDays = 0,
    required this.color,
    required this.createdAt,
    this.role,
  });

  int get remainingAnnualDays => totalAnnualDays - usedAnnualDays;

  Employee copyWith({
    String? id,
    String? name,
    DateTime? birthday,
    int? totalAnnualDays,
    int? usedAnnualDays,
    int? color,
    DateTime? createdAt,
    String? role,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      totalAnnualDays: totalAnnualDays ?? this.totalAnnualDays,
      usedAnnualDays: usedAnnualDays ?? this.usedAnnualDays,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}
