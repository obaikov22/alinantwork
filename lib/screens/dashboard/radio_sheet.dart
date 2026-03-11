import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/employee.dart';
import '../../providers/employees_provider.dart';
import '../../theme/app_theme.dart';

class RadioSheet extends ConsumerStatefulWidget {
  const RadioSheet({super.key});

  @override
  ConsumerState<RadioSheet> createState() => _RadioSheetState();
}

class _RadioSheetState extends ConsumerState<RadioSheet> {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _employees =>
      _db.collection('users').doc(_uid).collection('employees');

  Map<String, String?>? _radioNumbers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRadioNumbers();
  }

  Future<void> _fetchRadioNumbers() async {
    final snap = await _employees.get();
    final map = <String, String?>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      map[doc.id] = data['radioNumber'] as String?;
    }
    if (mounted) {
      setState(() {
        _radioNumbers = map;
        _loading = false;
      });
    }
  }

  Future<void> _editRadioNumber(Employee emp) async {
    final current = _radioNumbers?[emp.id] ?? '';
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          emp.name,
          style: GoogleFonts.sora(
              color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.dmMono(color: AppColors.text, fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Radio number',
            labelStyle: GoogleFonts.sora(color: AppColors.textMuted),
            hintText: 'e.g. CH01, R-12',
            hintStyle:
                GoogleFonts.sora(color: AppColors.textMuted.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gradientStart),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.sora(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: ShaderMask(
              shaderCallback: (b) => AppColors.gradient.createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text('Save',
                  style: GoogleFonts.sora(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
    if (result == null) return;
    final value = result.isEmpty ? null : result;
    await _employees.doc(emp.id).update({'radioNumber': value});
    setState(() {
      _radioNumbers = {...?_radioNumbers, emp.id: value};
    });
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final sorted = [...employees]..sort((a, b) => a.name.compareTo(b.name));
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShaderMask(
                shaderCallback: (b) => AppColors.gradient.createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Radio Numbers',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),

          // Content
          Flexible(
            child: _loading
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : sorted.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No employees yet',
                            style: GoogleFonts.sora(
                                color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.border,
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (ctx, i) {
                          final emp = sorted[i];
                          final radioNum = _radioNumbers?[emp.id];
                          final avatarColor = Color(emp.color);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: avatarColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _initials(emp.name),
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: avatarColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              emp.name,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            trailing: Text(
                              radioNum ?? '—',
                              style: GoogleFonts.dmMono(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: radioNum != null
                                    ? AppColors.gradientStart
                                    : AppColors.textMuted,
                              ),
                            ),
                            onTap: () => _editRadioNumber(emp),
                          );
                        },
                      ),
          ),

          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
}
