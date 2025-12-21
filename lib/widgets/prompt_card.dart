import 'package:flutter/material.dart';
import 'package:travel_memoir_admin/models/prompt_model.dart';

class PromptCard extends StatelessWidget {
  final PromptModel prompt;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                prompt.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: prompt.isActive,
                onChanged: onToggle,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prompt.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
