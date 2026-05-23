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
  final TextEditingController _searchController = TextEditingController();

  int? _sortColumnIndex;
  bool _sortAscending = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _num(double value) {
    // Hiển thị đẹp hơn: 6.0 -> 6, 8.32 -> 8.32
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  List<StudentGrade> get _visibleRows {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = widget.rows.where((student) {
      if (query.isEmpty) return true;

      return student.rollNumber.toLowerCase().contains(query) ||
          student.fullName.toLowerCase().contains(query);
    }).toList();

    final sortColumnIndex = _sortColumnIndex;
    if (sortColumnIndex == null) return filtered;

    filtered.sort((a, b) {
      final comparison = _scoreForColumn(
        a,
        sortColumnIndex,
      ).compareTo(_scoreForColumn(b, sortColumnIndex));

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  double _scoreForColumn(StudentGrade student, int columnIndex) {
    return switch (columnIndex) {
      2 => student.finalExam,
      3 => student.finalResit,
      4 => student.practical,
      5 => student.practicalResit,
      6 => student.pt1,
      7 => student.pt2,
      8 => student.pt3,
      9 => student.project,
      10 => student.total,
      _ => 0,
    };
  }

  void _onScoreSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[
      const DataColumn(label: SizedBox(width: 110, child: Text('Roll Number'))),
      const DataColumn(label: SizedBox(width: 170, child: Text('Full Name'))),

      DataColumn(
        label: const SizedBox(width: 100, child: Text('Final Exam')),
        onSort: _onScoreSort,
      ),
      DataColumn(
        label: const SizedBox(width: 110, child: Text('Final Exam Resit')),
        onSort: _onScoreSort,
      ),
      DataColumn(
        label: const SizedBox(width: 110, child: Text('Practical Exam')),
        onSort: _onScoreSort,
      ),
      DataColumn(
        label: const SizedBox(width: 110, child: Text('Practical Exam Resit')),
        onSort: _onScoreSort,
      ),
      DataColumn(
        label: const SizedBox(width: 120, child: Text('Progress Test 1')),
        onSort: _onScoreSort,
      ),

      DataColumn(
        label: const SizedBox(width: 120, child: Text('Progress Test 2')),
        onSort: _onScoreSort,
      ),

      DataColumn(
        label: const SizedBox(width: 120, child: Text('Progress Test 3')),
        onSort: _onScoreSort,
      ),

      DataColumn(
        label: const SizedBox(width: 110, child: Text('Project')),
        onSort: _onScoreSort,
      ),

      DataColumn(
        label: const SizedBox(width: 100, child: Text('Total')),
        onSort: _onScoreSort,
      ),
      const DataColumn(label: SizedBox(width: 100, child: Text('Result'))),

      const DataColumn(label: SizedBox(width: 100, child: Text('Detail'))),
    ];
    final visibleRows = _visibleRows;
    final rows = visibleRows.map((s) {
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
            SizedBox(
              width: 360,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  hintText: 'Search by name or roll number',
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: visibleRows.isEmpty
                  ? const Center(
                      child: Text(
                        'No students match your search.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : Scrollbar(
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
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
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
