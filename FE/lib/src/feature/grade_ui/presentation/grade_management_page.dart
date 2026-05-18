import 'package:fe/src/feature/grade_ui/data/grade_api_service.dart';
import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/ai_pannel_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/empty_state_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_header_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_table_card.dart';
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

  List<String> _classOptions = [];

  String? _selectedClass;

  List<StudentGrade> _rows = [];

  late final GradeApiService _api = GradeApiService(
    baseUrl: "http://localhost:8080",
  );

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles();
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

  void _exportFile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Exporting file...")));
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = _showTable
        ? GradeTableCard(className: _selectedClass ?? '', rows: _rows)
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
                onExportPressed: _showTable ? _exportFile : null,
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
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: mainContent),
                          if (_showTable) ...[
                            const SizedBox(width: 12),
                            const SizedBox(width: 300, child: AiPannelCard()),
                          ],
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(child: mainContent),
                        if (_showTable) ...[
                          const SizedBox(height: 12),
                          const SizedBox(height: 220, child: AiPannelCard()),
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
