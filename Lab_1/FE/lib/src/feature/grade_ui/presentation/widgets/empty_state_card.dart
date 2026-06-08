import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.description_outlined,
                size: 62,
                color: Color(0xFFBFC5D0),
              ),
              SizedBox(height: 10),
              Text(
                "No Grade",
                style: TextStyle(
                  fontSize: 30 / 2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 4),

              Text(
                "Please import a file to get started.",
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
