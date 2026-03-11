import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class BinsSheet extends StatefulWidget {
  const BinsSheet({super.key});

  @override
  State<BinsSheet> createState() => _BinsSheetState();
}

class _BinsSheetState extends State<BinsSheet> {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _binFloors =>
      _db.collection('users').doc(_uid).collection('bin_floors');

  List<({String id, String floorName, int binCount})>? _floors;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final snap = await _binFloors.get();
    final floors = snap.docs.map((d) {
      final data = d.data();
      return (
        id: d.id,
        floorName: data['floorName'] as String,
        binCount: (data['binCount'] as num).toInt(),
      );
    }).toList();
    floors.sort((a, b) => a.floorName.compareTo(b.floorName));
    if (mounted) {
      setState(() {
        _floors = floors;
        _loading = false;
      });
    }
  }

  Future<void> _editBinCount(
      String id, String floorName, int current) async {
    final ctrl = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          floorName,
          style: GoogleFonts.sora(
              color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.dmMono(color: AppColors.text, fontSize: 20),
          decoration: InputDecoration(
            labelText: 'Bin count',
            labelStyle: GoogleFonts.sora(color: AppColors.textMuted),
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
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
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
    await _binFloors.doc(id).update({'binCount': result});
    _fetch();
  }

  Future<void> _addFloor() async {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '0');
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Floor',
          style: GoogleFonts.sora(
              color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: GoogleFonts.sora(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Floor name',
                labelStyle: GoogleFonts.sora(color: AppColors.textMuted),
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
            const SizedBox(height: 12),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.dmMono(color: AppColors.text, fontSize: 20),
              decoration: InputDecoration(
                labelText: 'Bin count',
                labelStyle: GoogleFonts.sora(color: AppColors.textMuted),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.sora(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final count = int.tryParse(countCtrl.text) ?? 0;
              if (name.isNotEmpty) Navigator.pop(ctx, (name, count));
            },
            child: ShaderMask(
              shaderCallback: (b) => AppColors.gradient.createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text('Add',
                  style: GoogleFonts.sora(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
    if (result == null) return;
    final (name, count) = result;
    await _binFloors.add({'floorName': name, 'binCount': count});
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final bottomPad =
        MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom;

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
                  'Bin Management',
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
                : _floors!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No floors added yet',
                            style: GoogleFonts.sora(
                                color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: _floors!.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.border,
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (ctx, i) {
                          final floor = _floors![i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            title: Text(
                              floor.floorName,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.gradientStart
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${floor.binCount}',
                                style: GoogleFonts.dmMono(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gradientStart,
                                ),
                              ),
                            ),
                            onTap: () => _editBinCount(
                                floor.id, floor.floorName, floor.binCount),
                          );
                        },
                      ),
          ),

          // Add Floor button
          Divider(color: AppColors.border, height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
            child: GestureDetector(
              onTap: _addFloor,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradientStart.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Add Floor',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
