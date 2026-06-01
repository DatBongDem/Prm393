import 'package:fe/src/feature/grade_ui/data/grade_api_service.dart';
import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/ai_pannel_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/empty_state_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_form_dialog.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_header_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_table_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/resizable_panel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class GradeManagementPage extends StatefulWidget {
  const GradeManagementPage({super.key});

  @override
  State<GradeManagementPage> createState() => _GradeManagementPageState();
}

class _GradeManagementPageState extends State<GradeManagementPage> {
  bool _showTable = false;
  bool _isImporting = false;
  bool _isExporting = false;

  List<String> _classOptions = [];

  String? _selectedClass;

  List<StudentGrade> _rows = [];

  late final GradeApiService _api = GradeApiService(
    baseUrl: "http://localhost:8080",
  );

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fg', 'xls', 'xlsx', 'xml'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final file = result.files.first;
      final response = await _api.uploadGradeFile(file);

      setState(() {
        _apiCache = response.classes;

        _classOptions = response.classes.keys.toList();

        _selectedClass = _classOptions.isNotEmpty ? _classOptions.first : null;

        _rows = _selectedClass != null
            ? response.classes[_selectedClass!] ?? []
            : [];

        _showTable = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Map<String, List<StudentGrade>> _apiCache = {};
  void _onClassChanged(String? value) {
    if (value == null) return;

    setState(() {
      _selectedClass = value;

      _rows = _apiCache[value] ?? [];
    });
  }

  Future<void> _exportFile() async {
    final format = await _chooseExportFormat();
    if (format == null) return;

    setState(() => _isExporting = true);

    try {
      final exportFile = await _api.exportGradeFile(format);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save exported grade file',
        fileName: exportFile.fileName,
        type: FileType.custom,
        allowedExtensions: [exportFile.extension],
        bytes: exportFile.bytes,
        lockParentWindow: true,
      );

      if (!mounted || path == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported successfully: $path')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<GradeExportFormat?> _chooseExportFormat() {
    return showDialog<GradeExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.file_download_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Export file',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ExportOptionTile(
                icon: Icons.table_chart_outlined,
                title: 'Excel workbook',
                subtitle: 'Save the current grade data as .xlsx',
                color: const Color(0xFF1D7A46),
                onTap: () => Navigator.pop(context, GradeExportFormat.excel),
              ),
              const SizedBox(height: 10),
              _ExportOptionTile(
                icon: Icons.description_outlined,
                title: 'FG file',
                subtitle: 'Save the current grade data as .fg',
                color: const Color(0xFF2B6DE9),
                onTap: () => Navigator.pop(context, GradeExportFormat.fg),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _createStudent() async {
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or import a class first.")),
      );
      return;
    }

    final request = await GradeFormDialog.show(
      context,
      className: _selectedClass!,
    );

    if (request != null) {
      try {
        final newStudent = await _api.createStudent(request);
        setState(() {
          _rows.add(newStudent);
          _apiCache[_selectedClass!] = _rows;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student created successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to create student: $e")));
      }
    }
  }

  Future<void> _editStudent(StudentGrade student) async {
    final request = await GradeFormDialog.show(
      context,
      className: _selectedClass!,
      student: student,
    );

    if (request != null) {
      try {
        final updatedStudent = await _api.updateStudent(
          student.rollNumber,
          request,
        );
        setState(() {
          final index = _rows.indexWhere(
            (s) => s.rollNumber == student.rollNumber,
          );
          if (index != -1) {
            _rows[index] = updatedStudent;
            _apiCache[_selectedClass!] = _rows;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student updated successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update student: $e")));
      }
    }
  }

  Future<void> _deleteStudent(StudentGrade student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
          "Are you sure you want to delete student ${student.fullName}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteStudent(student.rollNumber);
        setState(() {
          _rows.removeWhere((s) => s.rollNumber == student.rollNumber);
          _apiCache[_selectedClass!] = _rows;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student deleted successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete student: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = _showTable
        ? GradeTableCard(
            className: _selectedClass ?? '',
            rows: _rows,
            onEdit: _editStudent,
            onDelete: _deleteStudent,
          )
        : const EmptyStateCard();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GradeHeaderCard(
                isImporting: _isImporting,
                onImportPressed: _importFile,
                onCreatePressed: _createStudent,
                onExportPressed: _showTable && !_isExporting
                    ? _exportFile
                    : null,
                classOptions: _classOptions,
                selectedClass: _selectedClass,
                onClassChanged: _onClassChanged,
              ),
              const SizedBox(height: 12),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1450;

                    if (isWide) {
                      final maxAiWidth = (constraints.maxWidth * 0.45).clamp(
                        300.0,
                        560.0,
                      );

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: mainContent),
                          if (_showTable) ...[
                            const SizedBox(width: 12),
                            ResizablePanel(
                              initialWidth: 340,
                              initialHeight: constraints.maxHeight,
                              minWidth: 300,
                              maxWidth: maxAiWidth,
                              child: const AiPannelCard(),
                            ),
                          ],
                        ],
                      );
                    }

                    final maxAiHeight = (constraints.maxHeight * 0.55).clamp(
                      220.0,
                      420.0,
                    );

                    return Column(
                      children: [
                        Expanded(child: mainContent),
                        if (_showTable) ...[
                          const SizedBox(height: 12),
                          ResizablePanel(
                            initialWidth: constraints.maxWidth,
                            initialHeight: 260,
                            minHeight: 220,
                            maxHeight: maxAiHeight,
                            isHorizontal: false,
                            child: const AiPannelCard(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
