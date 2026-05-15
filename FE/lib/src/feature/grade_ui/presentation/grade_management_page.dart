import 'package:fe/src/feature/grade_ui/presentation/widgets/ai_pannel_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/empty_state_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_header_card.dart';
import 'package:fe/src/feature/grade_ui/presentation/widgets/grade_table_card.dart';
import 'package:flutter/material.dart';

class GradeManagementPage extends StatefulWidget {
  const GradeManagementPage({super.key});

  @override
  State<GradeManagementPage> createState() => _GradeManagementPageState();
}

class _GradeManagementPageState extends State<GradeManagementPage> {
  bool _showTable = false;

  final List<String> _classOptions = const [
    'SE1813',
    'SE1814',
    'SE1815',
    'SE1816',
  ];

  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GradeHeaderCard(
                showTable: _showTable,
                onToggle: (value) {
                  setState(() => _showTable = value);
                },
                onImportPressed: () {},
                onExportPressed: _showTable ? () {} : null,

                classOptions: _classOptions,
                selectedClass: _selectedClass,
                onClassChanged: (value) {
                  setState(() => _selectedClass = value);
                },
              ),
              const SizedBox(height: 12),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1450;

                    final mainContent = _showTable
                        ? const GradeTableCard()
                        : const EmptyStateCard();

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
