import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/employee.dart';
import '../services/firestore_service.dart';

class EmployeesNotifier extends StateNotifier<List<Employee>> {
  EmployeesNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box<Employee>('employees');
    final list = box.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = list;
  }

  /// Called once after login: fetches from Firestore and updates local cache.
  /// If Firestore is empty but Hive has data, pushes local data to Firestore.
  Future<void> initialize() async {
    try {
      final remote = await FirestoreService.instance.fetchEmployees();
      if (remote.isNotEmpty) {
        final box = Hive.box<Employee>('employees');
        await box.clear();
        for (final e in remote) {
          await box.put(e.id, e);
        }
        remote.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = remote;
      } else if (state.isNotEmpty) {
        // First run: push local data up to Firestore.
        await FirestoreService.instance.syncEmployees(state);
      }
    } catch (_) {
      // Keep Hive data on network error.
    }
  }

  Future<void> addEmployee(Employee employee) async {
    final box = Hive.box<Employee>('employees');
    await box.put(employee.id, employee);
    state = [...state, employee];
    FirestoreService.instance.saveEmployee(employee).ignore();
  }

  Future<void> removeEmployee(String id) async {
    final box = Hive.box<Employee>('employees');
    await box.delete(id);
    state = state.where((e) => e.id != id).toList();
    FirestoreService.instance.deleteEmployee(id).ignore();
  }

  Future<void> updateEmployee(Employee employee) async {
    final box = Hive.box<Employee>('employees');
    await box.put(employee.id, employee);
    state = [
      for (final e in state)
        if (e.id == employee.id) employee else e,
    ];
    FirestoreService.instance.saveEmployee(employee).ignore();
  }
}

final employeesProvider =
    StateNotifierProvider<EmployeesNotifier, List<Employee>>(
  (ref) => EmployeesNotifier(),
);
