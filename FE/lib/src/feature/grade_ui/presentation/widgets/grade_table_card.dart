import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_detail_dialog.dart';
import 'package:flutter/material.dart';

final List<_ScoreColumn> _allScoreColumns = [
  _ScoreColumn(
    label: 'Final Exam',
    width: 100,
    valueOf: (student) => student.finalExam,
  ),
  _ScoreColumn(
    label: 'Final Exam Resit',
    width: 110,
    valueOf: (student) => student.finalResit,
  ),
  _ScoreColumn(
    label: 'Practical Exam',
    width: 110,
    valueOf: (student) => student.practical,
  ),
  _ScoreColumn(
    label: 'Practical Exam Resit',
    width: 110,
    valueOf: (student) => student.practicalResit,
  ),
  _ScoreColumn(
    label: 'Progress Test 1',
    width: 120,
    valueOf: (student) => student.pt1,
  ),
  _ScoreColumn(
    label: 'Progress Test 2',
    width: 120,
    valueOf: (student) => student.pt2,
  ),
  _ScoreColumn(
    label: 'Progress Test 3',
    width: 120,
    valueOf: (student) => student.pt3,
  ),
  _ScoreColumn(
    label: 'Assignment 1',
    width: 110,
    valueOf: (student) => student.assignment1,
  ),
  _ScoreColumn(
    label: 'Assignment 2',
    width: 110,
    valueOf: (student) => student.assignment2,
  ),
  _ScoreColumn(
    label: 'Assignment 3',
    width: 110,
    valueOf: (student) => student.assignment3,
  ),
  _ScoreColumn(
    label: 'Project',
    width: 110,
    valueOf: (student) => student.project,
  ),
  _ScoreColumn(label: 'Total', width: 100, valueOf: (student) => student.total),
];

class GradeTableCard extends StatefulWidget {
  const GradeTableCard({
    super.key,
    required this.className,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final String className;
  final List<StudentGrade> rows;
  final Function(StudentGrade) onEdit;
  final Function(StudentGrade) onDelete;

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

  String _num(double? value) {
    if (value == null) return '-';
    // Hiển thị đẹp hơn: 6.0 -> 6, 8.32 -> 8.32
    return value.toStringAsFixed(1);
  }

  List<StudentGrade> _visibleRows(List<_ScoreColumn> scoreColumns) {
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
        scoreColumns,
      ).compareTo(_scoreForColumn(b, sortColumnIndex, scoreColumns));

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  double _scoreForColumn(
    StudentGrade student,
    int columnIndex,
    List<_ScoreColumn> scoreColumns,
  ) {
    final scoreIndex = columnIndex - 2;
    if (scoreIndex < 0 || scoreIndex >= scoreColumns.length) {
      return double.negativeInfinity;
    }

    return scoreColumns[scoreIndex].valueOf(student) ?? double.negativeInfinity;
  }

  void _onScoreSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<_ScoreColumn> _visibleScoreColumns() {
    return _allScoreColumns
        .where(
          (column) =>
              widget.rows.any((student) => column.valueOf(student) != null),
        )
        .toList();
  }

  bool _isVisibleScoreColumnIndex(
    int? columnIndex,
    List<_ScoreColumn> scoreColumns,
  ) {
    if (columnIndex == null) return false;
    final scoreIndex = columnIndex - 2;
    return scoreIndex >= 0 && scoreIndex < scoreColumns.length;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColumns = _visibleScoreColumns();
    final showResultColumn = widget.rows.any(
      (student) => student.result.isNotEmpty,
    );
    final visibleRows = _visibleRows(scoreColumns);
    final activeSortColumnIndex =
        _isVisibleScoreColumnIndex(_sortColumnIndex, scoreColumns)
        ? _sortColumnIndex
        : null;
    final columns = <DataColumn>[
      const DataColumn(label: SizedBox(width: 110, child: Text('Roll Number'))),
      const DataColumn(label: SizedBox(width: 170, child: Text('Full Name'))),

      for (final scoreColumn in scoreColumns)
        DataColumn(
          label: SizedBox(
            width: scoreColumn.width,
            child: Text(scoreColumn.label),
          ),
          onSort: _onScoreSort,
        ),
      if (showResultColumn)
        const DataColumn(label: SizedBox(width: 100, child: Text('Result'))),

      const DataColumn(label: SizedBox(width: 150, child: Text('Actions'))),
    ];
    final rows = visibleRows.map((s) {
      return DataRow(
        cells: [
          DataCell(Text(s.rollNumber)),
          DataCell(Text(s.fullName)),
          for (final scoreColumn in scoreColumns)
            DataCell(Text(_num(scoreColumn.valueOf(s)))),
          if (showResultColumn) DataCell(_ResultChip(result: s.result)),
          DataCell(
            Row(
              children: [
                IconButton(
                  tooltip: 'View detail',
                  icon: const Icon(
                    Icons.visibility,
                    size: 20,
                    color: Colors.blue,
                  ),
                  onPressed: () => GradeDetailDialog.show(context, s),
                ),
                IconButton(
                  tooltip: 'Edit student',
                  icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                  onPressed: () => widget.onEdit(s),
                ),
                IconButton(
                  tooltip: 'Delete student',
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => widget.onDelete(s),
                ),
              ],
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
                              sortColumnIndex: activeSortColumnIndex,
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
  const _ResultChip({required this.result});
  final String result;

  @override
  Widget build(BuildContext context) {
    final normalized = result.toUpperCase();
    final isPass = normalized == 'PASS';
    final hasResult = normalized == 'PASS' || normalized == 'FAIL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: !hasResult
            ? const Color(0xFFF3F4F6)
            : isPass
            ? const Color(0xFFEAFBF1)
            : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        hasResult ? normalized : '-',
        style: TextStyle(
          color: !hasResult
              ? const Color(0xFF6B7280)
              : isPass
              ? const Color(0xFF1D7A46)
              : const Color(0xFFD93C3C),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreColumn {
  const _ScoreColumn({
    required this.label,
    required this.width,
    required this.valueOf,
  });

  final String label;
  final double width;
  final double? Function(StudentGrade student) valueOf;
}
