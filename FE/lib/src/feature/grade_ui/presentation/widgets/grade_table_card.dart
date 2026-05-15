import 'package:flutter/material.dart';

class GradeTableCard extends StatefulWidget {
  const GradeTableCard({super.key});

  @override
  State<StatefulWidget> createState() => _GradeManagementPageState();
}

class _GradeManagementPageState extends State<GradeTableCard> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();

  static const List<String> _headers = [
    "Email",
    "MemberCode",
    "FullName",
    "Final Exam",
    "Final Exam Resit",
    "Pratical Exam",
    "Progress Test 1",
    "Progress Test 2",
    "Progress Test 3",
    "Project",
    "Averrage",
    "Status",
  ];
  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final rows = List<DataRow>.generate(28, (index) {
      return DataRow(
        cells: [
          const DataCell(Text('-')),
          DataCell(Text('SE18${100 + index}')),
          DataCell(Text('Student ${index + 1}')),
          const DataCell(Text('-')),
          const DataCell(Text('-')),
          const DataCell(Text('-')),
          const DataCell(Text('-')),
          const DataCell(Text('-')),
          const DataCell(Text('-')),
          const DataCell(Text('-')),
          const DataCell(Text('0.0')),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Failed",
                style: TextStyle(
                  color: Color(0xFFD93C3C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Board Grade - Sheet 1",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
                        dataRowMaxHeight: 40,
                        columnSpacing: 14,
                        showCheckboxColumn: false,
                        columns: _headers
                            .map(
                              (header) => DataColumn(
                                label: SizedBox(
                                  width: 110,
                                  child: Text(
                                    header,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
