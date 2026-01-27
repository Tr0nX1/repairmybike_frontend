import 'package:flutter/material.dart';

class VehicleTypeSelector extends StatelessWidget {
  const VehicleTypeSelector({super.key, required this.onSelected});
  final void Function(String type) onSelected;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF01C9F5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'What type of vehicle do you have?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => onSelected('scooter'),
          icon: const Icon(Icons.two_wheeler),
          label: const Text('Scooter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onSelected('motorcycle'),
          icon: const Icon(Icons.motorcycle, color: accent),
          label: const Text('Motorcycle'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: accent),
            foregroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
