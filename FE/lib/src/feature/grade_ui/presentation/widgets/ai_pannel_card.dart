import 'package:flutter/material.dart';

class AiPannelCard extends StatelessWidget {
  const AiPannelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "AI Chat Bot",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 16),
            const Expanded(
              child: Center(
                child: Text(
                  'Ask about your grade data.\nExample: "How many students passed?"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter your question...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton.filled(
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
