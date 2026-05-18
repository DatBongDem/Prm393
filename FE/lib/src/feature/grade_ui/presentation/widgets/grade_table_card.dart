import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_detail_dialog.dart';
import 'package:flutter/material.dart';

class GradeTableCard extends StatefulWidget {
  const GradeTableCard({
    super.key,
    required this.className,
    required this.rows,
  });

  final String className;
  final List<StudentGrade> rows;

  @override
  State<GradeTableCard> createState() => _GradeTableCardState();
}

class _GradeTableCardState extends State<GradeTableCard> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  String _num(double value) {
    // Hiển thị đẹp hơn: 6.0 -> 6, 8.32 -> 8.32
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  void _showDetailDialog(BuildContext context, StudentGrade s) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('${s.rollNumber} - ${s.fullName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Final', s.finalExam),
                Text('Comment: ${s.finalComment}'),

                const SizedBox(height: 8),

                _row('Final Resit', s.finalResit),
                _row('Practical', s.practical),

                const SizedBox(height: 8),

                _row('Progress Test 1', s.pt1),
                Text('Progress Test 1 Comment: ${s.pt1Comment}'),

                _row('Progress Test 2', s.pt2),
                Text('Progress Test 2 Comment: ${s.pt2Comment}'),

                _row('Progress Test 3', s.pt3),
                Text('Progress Test 3 Comment: ${s.pt3Comment}'),

                const SizedBox(height: 8),

                _row('Project', s.project),
                Text('Project Comment: ${s.projectComment}'),

                const Divider(),

                _row('Total', s.total),
                Text('Result: ${s.result}'),
                Text('Comment: ${s.comment}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: ${_num(value)}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[
      DataColumn(label: SizedBox(width: 110, child: Text('Roll No.'))),
      DataColumn(label: SizedBox(width: 170, child: Text('Full Name'))),

      DataColumn(label: SizedBox(width: 100, child: Text('Final'))),
      DataColumn(label: SizedBox(width: 110, child: Text('Final Resit'))),
      DataColumn(label: SizedBox(width: 110, child: Text('Practical'))),
      DataColumn(label: SizedBox(width: 110, child: Text('Practical Resit'))),
      DataColumn(label: SizedBox(width: 120, child: Text('Progress Test 1'))),

      DataColumn(label: SizedBox(width: 120, child: Text('Progress Test 2'))),

      DataColumn(label: SizedBox(width: 120, child: Text('Progress Test 3'))),

      DataColumn(label: SizedBox(width: 110, child: Text('Project'))),

      DataColumn(label: SizedBox(width: 100, child: Text('Total'))),
      DataColumn(label: SizedBox(width: 100, child: Text('Result'))),

      DataColumn(label: SizedBox(width: 100, child: Text('Detail'))),
    ];
    final rows = widget.rows.map((s) {
      return DataRow(
        cells: [
          DataCell(Text(s.rollNumber)),
          DataCell(Text(s.fullName)),
          DataCell(Text(_num(s.finalExam))),
          DataCell(Text(_num(s.finalResit))),
          DataCell(Text(_num(s.practical))),
          DataCell(Text(_num(s.practicalResit))),
          DataCell(Text(_num(s.pt1))),
          DataCell(Text(_num(s.pt2))),
          DataCell(Text(_num(s.pt3))),
          DataCell(Text(_num(s.project))),
          DataCell(Text(_num(s.total))),
          DataCell(_ResultChip(isPass: s.isPass)),
          DataCell(
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                GradeDetailDialog.show(context, s);
              },
            ),
          ),
        ],
      );
    }).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Board Grade - ${widget.className}',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Scrollbar(
                controller: _horizontal,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    controller: _vertical,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _vertical,
                      child: DataTable(
                        headingRowHeight: 42,
                        dataRowMinHeight: 36,
                        dataRowMaxHeight: 50,
                        columnSpacing: 14,
                        showCheckboxColumn: false,
                        columns: columns,
                        rows: rows,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.isPass});
  final bool isPass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPass ? const Color(0xFFEAFBF1) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPass ? 'PASS' : 'FAIL',
        style: TextStyle(
          color: isPass ? const Color(0xFF1D7A46) : const Color(0xFFD93C3C),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
